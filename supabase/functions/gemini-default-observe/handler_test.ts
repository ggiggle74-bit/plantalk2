import {
  createGeminiDefaultObserveHandler,
  type FetchLike,
  geminiDefaultObservationModel,
} from "./handler.ts";

const supabaseUrl = "https://project-ref.supabase.co";
const imageUrl =
  `${supabaseUrl}/storage/v1/object/public/plant-photos/plants/test/photo.jpg`;
const jpegBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
const pngBytes = new Uint8Array([
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
]);
const observedAt = new Date("2026-06-24T05:06:07Z");

Deno.test("handles CORS preflight without reading secrets", async () => {
  const handler = createGeminiDefaultObserveHandler({
    getEnv: () => {
      throw new Error("environment must not be read");
    },
    fetcher: async () => {
      throw new Error("fetch must not be called");
    },
  });

  const response = await handler(
    new Request("http://localhost/gemini-default-observe", {
      method: "OPTIONS",
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(
    response.headers.get("access-control-allow-methods"),
    "POST, OPTIONS",
  );
});

Deno.test("rejects unsupported methods", async () => {
  const handler = testHandler({ fetcher: neverFetch });
  const response = await handler(
    new Request("http://localhost/gemini-default-observe", { method: "GET" }),
  );

  assertEquals(response.status, 405);
  assertEquals((await responseJson(response)).error, "Method not allowed.");
});

Deno.test("requires Gemini and Supabase environment values", async () => {
  const missingKeyHandler = createGeminiDefaultObserveHandler({
    getEnv: (name) => (name === "SUPABASE_URL" ? supabaseUrl : undefined),
    fetcher: neverFetch,
  });
  const missingKey = await missingKeyHandler(jsonRequest({ imageUrl }));

  const missingUrlHandler = createGeminiDefaultObserveHandler({
    getEnv: (name) => (name === "GEMINI_API_KEY" ? "test-key" : undefined),
    fetcher: neverFetch,
  });
  const missingUrl = await missingUrlHandler(jsonRequest({ imageUrl }));

  assertEquals(missingKey.status, 500);
  assertIncludes(
    String((await responseJson(missingKey)).error),
    "GEMINI_API_KEY",
  );
  assertEquals(missingUrl.status, 500);
  assertIncludes(
    String((await responseJson(missingUrl)).error),
    "SUPABASE_URL",
  );
});

Deno.test(
  "validates JSON body and Storage image URL before fetching",
  async () => {
    let fetchCount = 0;
    const handler = testHandler({
      fetcher: async () => {
        fetchCount += 1;
        throw new Error("unexpected fetch");
      },
    });

    const malformed = await handler(
      new Request("http://localhost/gemini-default-observe", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: "{",
      }),
    );
    const nonObject = await handler(jsonRequest([]));
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
    assertEquals(nonObject.status, 400);
    assertEquals(missing.status, 400);
    assertEquals(foreignOrigin.status, 400);
    assertEquals(nonStorage.status, 400);
    assertEquals(fetchCount, 0);
  },
);

Deno.test(
  "downloads one image and sends a stateless schema-constrained interaction",
  async () => {
    const calls: Array<{ url: string; init?: RequestInit }> = [];
    const providerPayload = completedInteraction({
      image_quality: "usable",
      observation_state: "stable_appearance",
      evidence_tags: ["stable_foliage"],
      diagnosis: "must not escape",
      confidence: 0.99,
    });

    const fetcher: FetchLike = async (input, init) => {
      const url = input.toString();
      calls.push({ url, init });
      if (calls.length === 1) {
        return new Response(jpegBytes, { status: 200 });
      }
      if (calls.length === 2) {
        return Response.json(providerPayload);
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
    assertEquals(response.headers.get("cache-control"), "no-store");
    assertEquals(calls.length, 2);
    assertEquals(calls[0].url, imageUrl);
    assertEquals(calls[0].init?.method, "GET");
    assertEquals(calls[0].init?.redirect, "error");
    assertEquals(
      calls[1].url,
      "https://generativelanguage.googleapis.com/v1/interactions",
    );

    const headers = new Headers(calls[1].init?.headers);
    assertEquals(headers.get("x-goog-api-key"), "test-gemini-key");
    assertEquals(headers.get("cache-control"), "no-store");

    const providerRequest = JSON.parse(String(calls[1].init?.body)) as Record<
      string,
      unknown
    >;
    assertEquals(providerRequest.model, geminiDefaultObservationModel);
    assertEquals(providerRequest.store, false);
    assertIncludes(
      String(providerRequest.system_instruction),
      "Do not diagnose plant health",
    );

    const input = providerRequest.input as Array<Record<string, unknown>>;
    assertEquals(input[0].type, "text");
    assertIncludes(String(input[0].text), "non-diagnostic");
    assertEquals(input[1], {
      type: "image",
      data: "/9j/2Q==",
      mime_type: "image/jpeg",
    });

    const responseFormat = providerRequest.response_format as Record<
      string,
      unknown
    >;
    assertEquals(responseFormat.type, "text");
    assertEquals(responseFormat.mime_type, "application/json");
    const schema = responseFormat.schema as Record<string, unknown>;
    assertEquals(schema.additionalProperties, false);
    assertEquals(schema.required, [
      "image_quality",
      "observation_state",
      "evidence_tags",
    ]);
    const properties = schema.properties as Record<
      string,
      Record<string, unknown>
    >;
    assertEquals(properties.image_quality.enum, [
      "usable",
      "limited",
      "unusable",
    ]);
    assertEquals(properties.observation_state.enum, [
      "stable_appearance",
      "growth_positive",
      "new_leaf_observed",
      "flowering_observed",
      "visible_concern",
      "uncertain",
    ]);
    assert(!("observation_id" in properties));
    assert(!("observed_at" in properties));
    assert(!("diagnosis" in properties));

    assertEquals(providerRequest.generation_config, {
      temperature: 0,
      thinking_level: "minimal",
      thinking_summaries: "none",
      max_output_tokens: 160,
      tool_choice: "none",
    });

    assertEquals(decoded, {
      observation_id: "gateway-observation-id",
      observed_at: "2026-06-24T05:06:07.000Z",
      image_quality: "usable",
      observation_state: "stable_appearance",
      evidence_tags: ["stable_foliage"],
    });

    const serialized = JSON.stringify(decoded);
    assert(!serialized.includes("provider-interaction-id"));
    assert(!serialized.includes("must not escape"));
    assert(!serialized.includes("test-gemini-key"));
    assert(!serialized.includes("/9j/2Q=="));
    assertEquals(logs.length, 1);
  },
);

Deno.test("detects PNG bytes for the inline Gemini image", async () => {
  const calls: Array<{ url: string; init?: RequestInit }> = [];
  const handler = testHandler({
    fetcher: async (input, init) => {
      calls.push({ url: input.toString(), init });
      return calls.length === 1 ? new Response(pngBytes) : Response.json(
        completedInteraction({
          image_quality: "usable",
          observation_state: "flowering_observed",
          evidence_tags: ["flowering"],
        }),
      );
    },
  });

  const response = await handler(jsonRequest({ imageUrl }));
  const providerRequest = JSON.parse(String(calls[1].init?.body)) as Record<
    string,
    unknown
  >;
  const input = providerRequest.input as Array<Record<string, unknown>>;

  assertEquals(response.status, 200);
  assertEquals(input[1].mime_type, "image/png");
});

Deno.test(
  "degrades malformed or unapproved model content to a safe uncertainty",
  async () => {
    for (
      const modelText of [
        JSON.stringify({
          image_quality: "usable",
          observation_state: "stable_appearance",
          evidence_tags: ["stable_foliage", "unapproved_tag"],
        }),
        JSON.stringify({
          image_quality: "usable",
          observation_state: "water_needed",
          evidence_tags: [],
        }),
        "not-json",
        JSON.stringify(["not", "an", "object"]),
      ]
    ) {
      let callCount = 0;
      const handler = testHandler({
        fetcher: async () => {
          callCount += 1;
          if (callCount === 1) return new Response(jpegBytes);
          return Response.json(completedInteractionText(modelText));
        },
      });

      const response = await handler(jsonRequest({ imageUrl }));
      const decoded = await responseJson(response);

      assertEquals(response.status, 200);
      assertEquals(decoded, {
        observation_id: "gateway-observation-id",
        observed_at: "2026-06-24T05:06:07.000Z",
        image_quality: "unusable",
        observation_state: "uncertain",
        evidence_tags: ["image_unclear"],
      });
    }
  },
);

Deno.test(
  "rejects empty, unsupported, and oversized image responses",
  async () => {
    const responseFactories: Array<() => Response> = [
      () => new Response(new Uint8Array()),
      () => new Response(new Uint8Array([1, 2, 3, 4])),
      () =>
        new Response(null, {
          headers: { "content-length": String(10 * 1024 * 1024 + 1) },
        }),
    ];
    const expectedStatuses = [400, 400, 413];

    for (let index = 0; index < responseFactories.length; index++) {
      let callCount = 0;
      const handler = testHandler({
        fetcher: async () => {
          callCount += 1;
          return responseFactories[index]();
        },
      });

      const response = await handler(jsonRequest({ imageUrl }));
      assertEquals(response.status, expectedStatuses[index]);
      assertEquals(callCount, 1);
    }
  },
);

Deno.test("does not expose Gemini error bodies", async () => {
  let callCount = 0;
  const handler = testHandler({
    fetcher: async () => {
      callCount += 1;
      if (callCount === 1) return new Response(jpegBytes);
      return new Response(
        JSON.stringify({ apiKey: "leaked-key", detail: "provider-private" }),
        { status: 429 },
      );
    },
    logger: quietLogger,
  });

  const response = await handler(jsonRequest({ imageUrl }));
  const decoded = await responseJson(response);
  const serialized = JSON.stringify(decoded);

  assertEquals(response.status, 502);
  assertEquals(decoded.status, 429);
  assert(!serialized.includes("leaked-key"));
  assert(!serialized.includes("provider-private"));
});

Deno.test(
  "rejects invalid, incomplete, or output-less interaction responses",
  async () => {
    const providerResponses = [
      new Response("not-json", { status: 200 }),
      Response.json({
        id: "provider-interaction-id",
        status: "incomplete",
        steps: [],
      }),
      Response.json({
        id: "provider-interaction-id",
        status: "completed",
        steps: [{ type: "model_output", content: [] }],
      }),
    ];

    for (const providerResponse of providerResponses) {
      let callCount = 0;
      const handler = testHandler({
        fetcher: async () => {
          callCount += 1;
          return callCount === 1
            ? new Response(jpegBytes)
            : providerResponse.clone();
        },
      });

      const response = await handler(jsonRequest({ imageUrl }));
      assertEquals(response.status, 502);
    }
  },
);

function testHandler({
  fetcher,
  logger = quietLogger,
}: {
  fetcher: FetchLike;
  logger?: Pick<Console, "info" | "warn">;
}) {
  return createGeminiDefaultObserveHandler({
    getEnv: (name) => {
      if (name === "GEMINI_API_KEY") return "test-gemini-key";
      if (name === "SUPABASE_URL") return supabaseUrl;
      return undefined;
    },
    fetcher,
    logger,
    now: () => observedAt,
    createObservationId: () => "gateway-observation-id",
  });
}

function completedInteraction(modelOutput: Record<string, unknown>) {
  return completedInteractionText(JSON.stringify(modelOutput));
}

function completedInteractionText(text: string) {
  return {
    id: "provider-interaction-id",
    model: geminiDefaultObservationModel,
    status: "completed",
    steps: [
      {
        type: "model_output",
        content: [{ type: "text", text }],
      },
    ],
    usage: {
      total_input_tokens: 300,
      total_output_tokens: 24,
      total_tokens: 324,
    },
  };
}

function jsonRequest(body: unknown): Request {
  return new Request("http://localhost/gemini-default-observe", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

async function responseJson(
  response: Response,
): Promise<Record<string, unknown>> {
  const decoded: unknown = await response.json();
  assert(
    decoded !== null && typeof decoded === "object" && !Array.isArray(decoded),
  );
  return decoded as Record<string, unknown>;
}

const neverFetch: FetchLike = async () => {
  throw new Error("fetch must not be called");
};

const quietLogger: Pick<Console, "info" | "warn"> = {
  info: () => undefined,
  warn: () => undefined,
};

function assert(
  condition: unknown,
  message = "Assertion failed",
): asserts condition {
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
    throw new Error(
      `Expected ${JSON.stringify(actual)} to include ${
        JSON.stringify(expectedSubstring)
      }`,
    );
  }
}
