import {
  createPlantHealthAssessHandler,
  type FetchLike,
} from "./handler.ts";

const supabaseUrl = "https://project-ref.supabase.co";
const imageUrl = supabaseUrl +
  "/storage/v1/object/public/plant-photos/plants/test/photo.jpg";
const jpegBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
const reservationId = "reservation-0001";
const authorization = "Bearer test-access-token-that-is-long-enough";

Deno.test("handles CORS preflight without reading secrets", async () => {
  const handler = createPlantHealthAssessHandler({
    getEnv: () => {
      throw new Error("environment must not be read");
    },
    fetcher: neverFetch,
  });

  const response = await handler(
    new Request("http://localhost/plant-health-assess", { method: "OPTIONS" }),
  );

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("access-control-allow-methods"), "POST, OPTIONS");
});

Deno.test("rejects unsupported methods", async () => {
  const response = await testHandler({ fetcher: neverFetch })(
    new Request("http://localhost/plant-health-assess", { method: "GET" }),
  );

  assertEquals(response.status, 405);
  assertEquals((await responseJson(response)).error, "Method not allowed.");
});

Deno.test("requires the Kindwise secret", async () => {
  const handler = createPlantHealthAssessHandler({
    getEnv: (name) => name === "SUPABASE_URL" ? supabaseUrl : undefined,
    fetcher: neverFetch,
    claimReservation: async () => true,
  });

  const response = await handler(jsonRequest({ imageUrl }));
  assertEquals(response.status, 500);
  assertIncludes(
    String((await responseJson(response)).error),
    "KINDWISE_PLANT_HEALTH_API_KEY",
  );
});

Deno.test("requires authenticated reservation input before fetching", async () => {
  let fetchCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      fetchCount += 1;
      throw new Error("unexpected fetch");
    },
  });

  const noAuth = await handler(
    jsonRequest({ imageUrl, reservationId }, { authorization: null }),
  );
  const noReservation = await handler(
    jsonRequest({ imageUrl, reservationId: "   " }),
  );
  const foreignImage = await handler(
    jsonRequest({
      imageUrl: "https://example.test/storage/v1/object/public/plant-photos/a.jpg",
    }),
  );

  assertEquals(noAuth.status, 401);
  assertEquals(noReservation.status, 400);
  assertEquals(foreignImage.status, 400);
  assertEquals(fetchCount, 0);
});

Deno.test("does not call Kindwise when server rejects the reservation claim", async () => {
  const calls: string[] = [];
  const handler = testHandler({
    fetcher: async (input) => {
      calls.push(input.toString());
      return new Response(jpegBytes);
    },
    claimReservation: async (input) => {
      assertEquals(input.authorization, authorization);
      assertEquals(input.reservationId, reservationId);
      return false;
    },
  });

  const response = await handler(jsonRequest({ imageUrl }));

  assertEquals(response.status, 403);
  assertEquals(calls, [imageUrl]);
  assertEquals(
    (await responseJson(response)).error,
    "Deep health usage reservation is not available.",
  );
});

Deno.test("claims once before the minimal Kindwise request", async () => {
  const calls: Array<{ url: string; init?: RequestInit }> = [];
  const claimCalls: Array<{ authorization: string; reservationId: string }> = [];
  const handler = testHandler({
    fetcher: async (input, init) => {
      calls.push({ url: input.toString(), init });
      if (calls.length === 1) return new Response(jpegBytes);
      if (calls.length === 2) return Response.json(healthyPayload());
      throw new Error("unexpected fetch");
    },
    claimReservation: async (input) => {
      claimCalls.push(input);
      return true;
    },
  });

  const response = await handler(jsonRequest({ imageUrl }));
  const decoded = await responseJson(response);

  assertEquals(response.status, 200);
  assertEquals(claimCalls, [{ authorization, reservationId }]);
  assertEquals(calls.length, 2);
  assertEquals(calls[0].url, imageUrl);

  const kindwiseUrl = new URL(calls[1].url);
  assertEquals(
    kindwiseUrl.origin + kindwiseUrl.pathname,
    "https://api.plant.id/v3/health_assessment",
  );
  assertEquals(
    kindwiseUrl.searchParams.get("details"),
    "local_name,description,treatment,cause",
  );

  const headers = new Headers(calls[1].init?.headers);
  assertEquals(headers.get("api-key"), "test-kindwise-key");
  assertEquals(JSON.parse(String(calls[1].init?.body)), {
    images: ["/9j/2Q=="],
  });
  assertEquals(decoded, {
    access_token: "fake-provider-result-token",
    model_version: "fake-model",
    created: 1782057600,
    status: "COMPLETED",
    result: {
      is_healthy: { binary: true, probability: 0.94, threshold: 0.63 },
      disease: { suggestions: [] },
    },
  });
});

Deno.test("does not expose provider secrets in upstream failures", async () => {
  let callCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      callCount += 1;
      if (callCount === 1) return new Response(jpegBytes);
      return Response.json(
        {
          message: "Invalid request.",
          apiKey: "leaked-key",
          authorization: "Bearer test-kindwise-key",
          image: "/9j/" + "A".repeat(120),
        },
        { status: 400 },
      );
    },
  });

  const response = await handler(jsonRequest({ imageUrl }));
  const decoded = await responseJson(response);
  const serialized = JSON.stringify(decoded);

  assertEquals(response.status, 502);
  assertEquals(decoded.status, 400);
  assert(!serialized.includes("test-kindwise-key"));
  assert(!serialized.includes("leaked-key"));
  assert(!serialized.includes("/9j/"));
});

Deno.test("rejects empty, unsupported, and oversized images before claiming", async () => {
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
    let claimCount = 0;
    const handler = testHandler({
      fetcher: async () => imageResponse,
      claimReservation: async () => {
        claimCount += 1;
        return true;
      },
    });

    const response = await handler(jsonRequest({ imageUrl }));
    assertEquals(response.status, expectedStatus);
    assertEquals(claimCount, 0);
  }
});

Deno.test("fails closed when reservation verification cannot be completed", async () => {
  const handler = testHandler({
    fetcher: async () => new Response(jpegBytes),
    claimReservation: async () => {
      throw new Error("rpc unavailable");
    },
  });

  const response = await handler(jsonRequest({ imageUrl }));
  assertEquals(response.status, 502);
  assertEquals(
    (await responseJson(response)).error,
    "Deep health usage could not be verified.",
  );
});

function testHandler({
  fetcher,
  claimReservation = async () => true,
}: {
  fetcher: FetchLike;
  claimReservation?: (input: {
    authorization: string;
    reservationId: string;
  }) => Promise<boolean>;
}) {
  return createPlantHealthAssessHandler({
    getEnv: (name) => {
      if (name === "KINDWISE_PLANT_HEALTH_API_KEY") return "test-kindwise-key";
      if (name === "SUPABASE_URL") return supabaseUrl;
      return undefined;
    },
    fetcher,
    claimReservation,
    logger: quietLogger,
  });
}

function jsonRequest(
  body: Record<string, unknown>,
  options: { authorization?: string | null } = {},
): Request {
  return new Request("http://localhost/plant-health-assess", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(options.authorization === null
        ? {}
        : { authorization: options.authorization ?? authorization }),
    },
    body: JSON.stringify({
      reservationId,
      ...body,
    }),
  });
}

function healthyPayload(): Record<string, unknown> {
  return {
    access_token: "fake-provider-result-token",
    model_version: "fake-model",
    created: 1782057600,
    status: "COMPLETED",
    result: {
      is_healthy: { binary: true, probability: 0.94, threshold: 0.63 },
      disease: { suggestions: [] },
    },
  };
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
    throw new Error("Expected " + expectedJson + ", received " + actualJson);
  }
}

function assertIncludes(actual: string, expectedSubstring: string): void {
  if (!actual.includes(expectedSubstring)) {
    throw new Error(
      "Expected " + JSON.stringify(actual) + " to include " +
        JSON.stringify(expectedSubstring),
    );
  }
}
