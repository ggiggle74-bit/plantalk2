import {
  createPlantHealthAssessHandler,
  type FetchLike,
} from "./handler.ts";

const supabaseUrl = "https://project-ref.supabase.co";
const imageUrl =
  `${supabaseUrl}/storage/v1/object/public/plant-photos/plants/test/photo.jpg`;
const jpegBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);

Deno.test("handles CORS preflight without reading secrets", async () => {
  const handler = createPlantHealthAssessHandler({
    getEnv: () => {
      throw new Error("environment must not be read");
    },
    fetcher: async () => {
      throw new Error("fetch must not be called");
    },
  });

  const response = await handler(
    new Request("http://localhost/plant-health-assess", { method: "OPTIONS" }),
  );

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("access-control-allow-methods"), "POST, OPTIONS");
});

Deno.test("rejects unsupported methods", async () => {
  const handler = testHandler({ fetcher: neverFetch });
  const response = await handler(
    new Request("http://localhost/plant-health-assess", { method: "GET" }),
  );

  assertEquals(response.status, 405);
  assertEquals((await responseJson(response)).error, "Method not allowed.");
});

Deno.test("requires the Kindwise secret", async () => {
  const handler = createPlantHealthAssessHandler({
    getEnv: (name) => name === "SUPABASE_URL" ? supabaseUrl : undefined,
    fetcher: neverFetch,
  });
  const response = await handler(jsonRequest({ imageUrl }));

  assertEquals(response.status, 500);
  assertIncludes(
    String((await responseJson(response)).error),
    "KINDWISE_PLANT_HEALTH_API_KEY",
  );
});

Deno.test("validates JSON body and imageUrl before fetching", async () => {
  let fetchCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      fetchCount += 1;
      throw new Error("unexpected fetch");
    },
  });

  const malformed = await handler(
    new Request("http://localhost/plant-health-assess", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{",
    }),
  );
  const missing = await handler(jsonRequest({}));
  const foreignOrigin = await handler(
    jsonRequest({
      imageUrl:
        "https://example.test/storage/v1/object/public/plant-photos/photo.jpg",
    }),
  );
  const nonStorage = await handler(
    jsonRequest({ imageUrl: `${supabaseUrl}/rest/v1/plants` }),
  );

  assertEquals(malformed.status, 400);
  assertEquals(missing.status, 400);
  assertEquals(foreignOrigin.status, 400);
  assertEquals(nonStorage.status, 400);
  assertEquals(fetchCount, 0);
});

Deno.test("downloads one Storage image and sends the minimal Kindwise request", async () => {
  const calls: Array<{ url: string; init?: RequestInit }> = [];
  const upstreamPayload = {
    access_token: "fake-provider-result-token",
    model_version: "fake-model",
    created: 1782057600,
    completed: 1782057601,
    status: "COMPLETED",
    input: {
      images: ["private-upstream-image"],
      latitude: 37.5,
      longitude: 127.0,
    },
    result: {
      is_plant: { binary: true, probability: 0.99 },
      is_healthy: { binary: false, probability: 0.18, threshold: 0.63 },
      disease: {
        suggestions: [
          {
            id: "fake-insect",
            name: "Insecta",
            probability: 0.72,
            redundant: false,
            similar_images: [{ url: "private-similar-image" }],
            details: {
              local_name: "해충 피해",
              description: "private-description",
              treatment: { chemical: ["private-treatment"] },
              cause: "private-cause",
            },
          },
        ],
      },
    },
  };

  const fetcher: FetchLike = async (input, init) => {
    const url = input.toString();
    calls.push({ url, init });
    if (calls.length === 1) {
      return new Response(jpegBytes, {
        status: 200,
        headers: { "content-type": "application/octet-stream" },
      });
    }
    if (calls.length === 2) {
      return Response.json(upstreamPayload);
    }
    throw new Error("unexpected fetch");
  };

  const logs: unknown[] = [];
  const handler = testHandler({
    fetcher,
    logger: {
      info: (...values: unknown[]) => logs.push(values),
      warn: (...values: unknown[]) => logs.push(values),
    },
  });
  const response = await handler(jsonRequest({ imageUrl }));
  const decoded = await responseJson(response);

  assertEquals(response.status, 200);
  assertEquals(calls.length, 2);
  assertEquals(calls[0].url, imageUrl);
  assertEquals(calls[0].init?.method, "GET");

  const kindwiseUrl = new URL(calls[1].url);
  assertEquals(kindwiseUrl.origin + kindwiseUrl.pathname, "https://api.plant.id/v3/health_assessment");
  assertEquals(
    kindwiseUrl.searchParams.get("details"),
    "local_name,description,treatment,cause",
  );
  assertEquals(kindwiseUrl.searchParams.get("language"), null);

  const headers = new Headers(calls[1].init?.headers);
  assertEquals(headers.get("api-key"), "test-kindwise-key");
  const providerRequest = JSON.parse(String(calls[1].init?.body)) as Record<string, unknown>;
  assertEquals(providerRequest, {
    images: ["/9j/2Q=="],
  });
  assert(!("similar_images" in providerRequest));
  assert(!("health" in providerRequest));
  assert(!("disease_level" in providerRequest));

  assertEquals(decoded, {
    access_token: "fake-provider-result-token",
    model_version: "fake-model",
    created: 1782057600,
    status: "COMPLETED",
    result: {
      is_healthy: { binary: false, probability: 0.18, threshold: 0.63 },
      disease: {
        suggestions: [
          {
            id: "fake-insect",
            name: "Insecta",
            probability: 0.72,
            redundant: false,
            details: {
              local_name: "해충 피해",
              classification: [],
              common_names: [],
            },
          },
        ],
      },
    },
  });

  const serialized = JSON.stringify(decoded);
  assert(!serialized.includes("private-upstream-image"));
  assert(!serialized.includes("private-similar-image"));
  assert(!serialized.includes("private-description"));
  assert(!serialized.includes("private-treatment"));
  assert(!serialized.includes("private-cause"));
  assert(!serialized.includes("test-kindwise-key"));
  assertEquals(logs.length, 1);
});

Deno.test("rejects empty, unsupported, and oversized image responses", async () => {
  for (const [imageResponse, expectedStatus] of [
    [new Response(new Uint8Array()), 400],
    [new Response(new Uint8Array([1, 2, 3, 4])), 400],
    [
      new Response(null, {
        headers: { "content-length": String(10 * 1024 * 1024 + 1) },
      }),
      413,
    ],
  ] as const) {
    let callCount = 0;
    const handler = testHandler({
      fetcher: async () => {
        callCount += 1;
        return imageResponse;
      },
    });

    const response = await handler(jsonRequest({ imageUrl }));
    assertEquals(response.status, expectedStatus);
    assertEquals(callCount, 1);
  }
});

Deno.test("includes sanitized upstream error details for non-OK Kindwise responses", async () => {
  let callCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      callCount += 1;
      if (callCount === 1) return new Response(jpegBytes);
      return Response.json(
        {
          message: "Invalid health assessment request.",
          apiKey: "leaked-key",
          headers: {
            authorization: "Bearer test-kindwise-key",
            "api-key": "test-kindwise-key",
          },
          image: `/9j/${"A".repeat(120)}`,
          detail: "provider-private-debug-detail",
        },
        { status: 400 },
      );
    },
    logger: quietLogger,
  });

  const response = await handler(jsonRequest({ imageUrl }));
  const decoded = await responseJson(response);
  const upstreamError = decoded.upstreamError as Record<string, unknown>;
  const serialized = JSON.stringify(decoded);

  assertEquals(response.status, 502);
  assertEquals(decoded.status, 400);
  assertEquals(decoded.error, "Kindwise plant health request failed.");
  assertEquals(upstreamError.message, "Invalid health assessment request.");
  assertEquals(upstreamError.apiKey, "[redacted]");
  assertEquals(upstreamError.headers, "[redacted]");
  assertEquals(upstreamError.image, "[redacted]");
  assertEquals(upstreamError.detail, "provider-private-debug-detail");
  assert(!serialized.includes("test-kindwise-key"));
  assert(!serialized.includes("leaked-key"));
  assert(!serialized.includes("Bearer"));
  assert(!serialized.includes("/9j/"));
});

Deno.test("truncates long upstream error text", async () => {
  let callCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      callCount += 1;
      if (callCount === 1) return new Response(jpegBytes);
      return new Response(`provider-error ${".".repeat(2000)}`, {
        status: 400,
      });
    },
    logger: quietLogger,
  });

  const response = await handler(jsonRequest({ imageUrl }));
  const decoded = await responseJson(response);

  assertEquals(response.status, 502);
  assertEquals(decoded.status, 400);
  assert(typeof decoded.upstreamError === "string");
  assertEquals(String(decoded.upstreamError).length, 1500);
  assert(String(decoded.upstreamError).startsWith("provider-error "));
});
Deno.test("sanitizes malformed provider fields to safe nulls and empty lists", async () => {
  let callCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      callCount += 1;
      if (callCount === 1) return new Response(jpegBytes);
      return Response.json({
        access_token: { private: true },
        created: false,
        result: {
          is_healthy: {
            binary: "false",
            probability: null,
            threshold: "not-a-number",
          },
          disease: {
            suggestions: [
              {
                id: "candidate",
                name: "Fungi",
                probability: true,
                details: {
                  local_name: ["private"],
                  classification: ["Fungi", null, 42],
                  common_names: "fungus",
                },
              },
            ],
          },
        },
      });
    },
  });

  const response = await handler(jsonRequest({ imageUrl }));
  const decoded = await responseJson(response);
  assertEquals(decoded, {
    access_token: null,
    model_version: null,
    created: null,
    status: null,
    result: {
      is_healthy: { binary: null, probability: null, threshold: null },
      disease: {
        suggestions: [
          {
            id: "candidate",
            name: "Fungi",
            probability: null,
            redundant: null,
            details: {
              local_name: null,
              classification: ["Fungi", "42"],
              common_names: [],
            },
          },
        ],
      },
    },
  });
});

Deno.test("rejects invalid successful upstream JSON", async () => {
  let callCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      callCount += 1;
      return callCount === 1
        ? new Response(jpegBytes)
        : new Response("not-json", { status: 200 });
    },
  });

  const response = await handler(jsonRequest({ imageUrl }));
  assertEquals(response.status, 502);
  assertIncludes(
    String((await responseJson(response)).error),
    "invalid JSON",
  );
});

function testHandler({
  fetcher,
  logger = quietLogger,
}: {
  fetcher: FetchLike;
  logger?: Pick<Console, "info" | "warn">;
}) {
  return createPlantHealthAssessHandler({
    getEnv: (name) => {
      if (name === "KINDWISE_PLANT_HEALTH_API_KEY") return "test-kindwise-key";
      if (name === "SUPABASE_URL") return supabaseUrl;
      return undefined;
    },
    fetcher,
    logger,
  });
}

function jsonRequest(body: unknown): Request {
  return new Request("http://localhost/plant-health-assess", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

async function responseJson(response: Response): Promise<Record<string, unknown>> {
  const decoded: unknown = await response.json();
  assert(decoded !== null && typeof decoded === "object" && !Array.isArray(decoded));
  return decoded as Record<string, unknown>;
}

const neverFetch: FetchLike = async () => {
  throw new Error("fetch must not be called");
};

const quietLogger: Pick<Console, "info" | "warn"> = {
  info: () => undefined,
  warn: () => undefined,
};

function assert(condition: unknown, message = "Assertion failed"): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown): void {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    throw new Error(`Expected ${expectedJson}, received ${actualJson}`);
  }
}

function assertIncludes(actual: string, expectedSubstring: string): void {
  if (!actual.includes(expectedSubstring)) {
    throw new Error(`Expected ${JSON.stringify(actual)} to include ${JSON.stringify(expectedSubstring)}`);
  }
}
