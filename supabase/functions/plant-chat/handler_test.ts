import { createPlantChatHandler } from './handler.ts';

const authorization = {
  authorization: `Bearer ${'a'.repeat(32)}`,
  'content-type': 'application/json',
};

Deno.test('rejects unauthenticated requests without calling Gemini', async () => {
  let callCount = 0;
  const handler = createPlantChatHandler({
    apiKey: 'test-key-that-is-long-enough',
    fetchImpl: async () => {
      callCount++;
      return providerResponse('unused');
    },
  });

  const response = await handler(
    new Request('https://example.com/plant-chat', {
      method: 'POST',
      body: JSON.stringify(validBody()),
    }),
  );

  assertEquals(response.status, 401);
  assertEquals(callCount, 0);
});

Deno.test('sends one bounded request and returns the text reply', async () => {
  let requestedUrl = '';
  let requestedApiKey = '';
  let providerRequest: Record<string, unknown> | null = null;
  const handler = createPlantChatHandler({
    apiKey: 'test-key-that-is-long-enough',
    fetchImpl: async (input, init) => {
      requestedUrl = input.toString();
      requestedApiKey = new Headers(init?.headers).get('x-goog-api-key') ?? '';
      providerRequest = JSON.parse(init?.body?.toString() ?? '{}');
      return providerResponse('  잎을 흔들며 기다리고 있었어.  ');
    },
  });

  const response = await handler(request(validBody()));
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.reply, '잎을 흔들며 기다리고 있었어.');
  assert(requestedUrl.includes('gemini-3.1-flash-lite:generateContent'));
  assertEquals(requestedApiKey, 'test-key-that-is-long-enough');
  assert(providerRequest != null);
  assert(JSON.stringify(providerRequest).includes('사용자 메시지: 우주에는 별이 몇 개야?'));
});

Deno.test('rejects oversized input before calling Gemini', async () => {
  let callCount = 0;
  const handler = createPlantChatHandler({
    apiKey: 'test-key-that-is-long-enough',
    fetchImpl: async () => {
      callCount++;
      return providerResponse('unused');
    },
  });

  const response = await handler(
    request(validBody({ message: '가'.repeat(501) })),
  );

  assertEquals(response.status, 400);
  assertEquals(callCount, 0);
});

Deno.test('fails closed when the provider response has no text', async () => {
  const handler = createPlantChatHandler({
    apiKey: 'test-key-that-is-long-enough',
    fetchImpl: async () =>
      new Response(JSON.stringify({ candidates: [] }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      }),
  });

  const response = await handler(request(validBody()));

  assertEquals(response.status, 502);
});

Deno.test('limits repeated requests for the same bearer token', async () => {
  const handler = createPlantChatHandler({
    apiKey: 'test-key-that-is-long-enough',
    maximumRequestsPerMinute: 1,
    fetchImpl: async () => providerResponse('첫 답변'),
  });

  const first = await handler(request(validBody()));
  const second = await handler(request(validBody()));

  assertEquals(first.status, 200);
  assertEquals(second.status, 429);
});

Deno.test('fails closed when the Gemini secret is absent', async () => {
  const handler = createPlantChatHandler({
    fetchImpl: async () => providerResponse('unused'),
  });

  const response = await handler(request(validBody()));

  assertEquals(response.status, 503);
});

function request(body: Record<string, unknown>): Request {
  return new Request('https://example.com/plant-chat', {
    method: 'POST',
    headers: authorization,
    body: JSON.stringify(body),
  });
}

function validBody(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    message: '우주에는 별이 몇 개야?',
    plantName: '무가리',
    species: '몬스테라',
    mood: 'calm',
    friendship: 12,
    locale: 'ko-KR',
    ...overrides,
  };
}

function providerResponse(reply: string): Response {
  return new Response(
    JSON.stringify({
      candidates: [
        {
          content: {
            parts: [{ text: reply }],
          },
        },
      ],
    }),
    {
      status: 200,
      headers: { 'content-type': 'application/json' },
    },
  );
}

function assert(condition: unknown, message = 'Assertion failed'): asserts condition {
  if (!condition) {
    throw new Error(message);
  }
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (!Object.is(actual, expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}
