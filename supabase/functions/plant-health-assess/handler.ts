import { corsHeaders } from "../_shared/cors.ts";

export type FetchLike = (
  input: RequestInfo | URL,
  init?: RequestInit,
) => Promise<Response>;

type EnvReader = (name: string) => string | undefined;

type Logger = Pick<Console, "info" | "warn">;

export type PlantHealthAssessDependencies = {
  getEnv: EnvReader;
  fetcher?: FetchLike;
  logger?: Logger;
};

type PlantHealthAssessRequest = {
  imageUrl?: unknown;
};

const kindwiseEndpoint = "https://api.plant.id/v3/health_assessment";
const requestedDetails = [
  "local_name",
  "description",
  "treatment",
  "cause",
] as const;
const maxImageBytes = 10 * 1024 * 1024;
const imageFetchTimeoutMs = 15_000;
const kindwiseFetchTimeoutMs = 30_000;
const maxUpstreamErrorChars = 1500;
const publicStoragePathPrefix = "/storage/v1/object/public/";

export function createPlantHealthAssessHandler(
  dependencies: PlantHealthAssessDependencies,
): (request: Request) => Promise<Response> {
  const fetcher = dependencies.fetcher ?? fetch;
  const logger = dependencies.logger ?? console;

  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return jsonResponse({ error: "Method not allowed." }, 405);
    }

    const apiKey = stringOrNull(
      dependencies.getEnv("KINDWISE_PLANT_HEALTH_API_KEY"),
    );
    if (!apiKey) {
      return jsonResponse(
        {
          error:
            "KINDWISE_PLANT_HEALTH_API_KEY Supabase Edge Function secret is missing.",
        },
        500,
      );
    }

    const supabaseOrigin = normalizedOrigin(
      dependencies.getEnv("SUPABASE_URL"),
    );
    if (!supabaseOrigin) {
      return jsonResponse(
        { error: "SUPABASE_URL Edge Function environment value is missing." },
        500,
      );
    }

    let body: PlantHealthAssessRequest;
    try {
      const decoded: unknown = await request.json();
      if (!isRecord(decoded)) {
        return jsonResponse({ error: "Request body must be a JSON object." }, 400);
      }
      body = decoded;
    } catch (_) {
      return jsonResponse({ error: "Request body must be valid JSON." }, 400);
    }

    const imageUrlResult = validatedImageUrl(body.imageUrl, supabaseOrigin);
    if ("error" in imageUrlResult) {
      return jsonResponse({ error: imageUrlResult.error }, 400);
    }

    let imageResponse: Response;
    try {
      imageResponse = await fetchWithTimeout(
        fetcher,
        imageUrlResult.url,
        {
          method: "GET",
          headers: { accept: "image/jpeg, image/png" },
          redirect: "follow",
        },
        imageFetchTimeoutMs,
      );
    } catch (_) {
      logger.warn("plant-health-assess image download failed");
      return jsonResponse({ error: "Plant image download failed." }, 502);
    }

    if (!imageResponse.ok) {
      logger.warn("plant-health-assess image download returned an error", {
        status: imageResponse.status,
      });
      return jsonResponse(
        {
          error: "imageUrl could not be fetched.",
          status: imageResponse.status,
        },
        400,
      );
    }

    let imageBytes: Uint8Array;
    try {
      imageBytes = await readResponseBytes(imageResponse, maxImageBytes);
    } catch (error) {
      if (error instanceof ImageTooLargeError) {
        return jsonResponse(
          { error: `Plant image must not exceed ${maxImageBytes} bytes.` },
          413,
        );
      }

      logger.warn("plant-health-assess image body could not be read");
      return jsonResponse({ error: "Plant image download failed." }, 502);
    }

    if (imageBytes.length === 0) {
      return jsonResponse({ error: "Plant image is empty." }, 400);
    }
    if (!isSupportedImage(imageBytes)) {
      return jsonResponse(
        { error: "Plant image must be JPEG or PNG." },
        400,
      );
    }

    const kindwiseUrl = new URL(kindwiseEndpoint);
    kindwiseUrl.searchParams.set("details", requestedDetails.join(","));

    let kindwiseResponse: Response;
    try {
      kindwiseResponse = await fetchWithTimeout(
        fetcher,
        kindwiseUrl,
        {
          method: "POST",
          headers: {
            accept: "application/json",
            "Content-Type": "application/json",
      "Cache-Control": "no-store",
            "Api-Key": apiKey,
          },
          body: JSON.stringify({
            images: [bytesToBase64(imageBytes)],
          }),
        },
        kindwiseFetchTimeoutMs,
      );
    } catch (_) {
      logger.warn("plant-health-assess upstream request failed");
      return jsonResponse(
        { error: "Kindwise plant health request failed." },
        502,
      );
    }

    if (!kindwiseResponse.ok) {
      const upstreamErrorText = await readResponseTextSnippet(
        kindwiseResponse,
        maxUpstreamErrorChars,
      );
      logger.warn("plant-health-assess upstream returned an error", {
        status: kindwiseResponse.status,
      });
      return jsonResponse(
        {
          error: "Kindwise plant health request failed.",
          status: kindwiseResponse.status,
          upstreamError: sanitizeUpstreamError(upstreamErrorText, [apiKey]),
        },
        502,
      );
    }

    const responseText = await kindwiseResponse.text();
    let decoded: unknown;
    try {
      decoded = JSON.parse(responseText);
    } catch (_) {
      return jsonResponse(
        { error: "Kindwise plant health returned invalid JSON." },
        502,
      );
    }

    if (!isRecord(decoded)) {
      return jsonResponse(
        { error: "Kindwise plant health returned an unexpected response." },
        502,
      );
    }

    const sanitized = sanitizeKindwiseResponse(decoded);
    logger.info("plant-health-assess succeeded", {
      status: kindwiseResponse.status,
      suggestionCount: suggestionCount(sanitized),
    });

    return jsonResponse(sanitized);
  };
}

export function sanitizeKindwiseResponse(
  decoded: Record<string, unknown>,
): Record<string, unknown> {
  const result = recordOrEmpty(decoded.result);
  const disease = recordOrEmpty(result.disease);
  const suggestions = Array.isArray(disease.suggestions)
    ? disease.suggestions.map(sanitizeSuggestion).filter(isNotNull)
    : [];

  return {
    access_token: stringOrNull(decoded.access_token),
    model_version: stringOrNull(decoded.model_version),
    created: numberOrStringOrNull(decoded.created),
    status: stringOrNull(decoded.status),
    result: {
      is_healthy: sanitizeEvaluation(result.is_healthy),
      disease: { suggestions },
    },
  };
}

function sanitizeEvaluation(value: unknown): Record<string, unknown> {
  const evaluation = recordOrEmpty(value);
  return {
    binary: typeof evaluation.binary === "boolean" ? evaluation.binary : null,
    probability: finiteNumberOrNull(evaluation.probability),
    threshold: finiteNumberOrNull(evaluation.threshold),
  };
}

function sanitizeSuggestion(value: unknown): Record<string, unknown> | null {
  if (!isRecord(value)) return null;

  const details = recordOrEmpty(value.details);
  return {
    id: stringOrNull(value.id),
    name: stringOrNull(value.name),
    probability: finiteNumberOrNull(value.probability),
    redundant: typeof value.redundant === "boolean" ? value.redundant : null,
    details: {
      local_name: stringOrNull(details.local_name),
      classification: stringList(details.classification),
      common_names: stringList(details.common_names),
    },
  };
}

function validatedImageUrl(
  value: unknown,
  supabaseOrigin: string,
): { url: URL } | { error: string } {
  const text = stringOrNull(value);
  if (!text) {
    return { error: "imageUrl is required." };
  }
  if (text.length > 4096) {
    return { error: "imageUrl is too long." };
  }

  let url: URL;
  try {
    url = new URL(text);
  } catch (_) {
    return { error: "imageUrl must be an absolute HTTP or HTTPS URL." };
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    return { error: "imageUrl must be an absolute HTTP or HTTPS URL." };
  }
  if (url.username || url.password || url.hash) {
    return { error: "imageUrl contains unsupported URL components." };
  }
  if (url.origin !== supabaseOrigin) {
    return {
      error: "imageUrl must use this Supabase project's Storage origin.",
    };
  }
  if (!url.pathname.startsWith(publicStoragePathPrefix)) {
    return { error: "imageUrl must point to a public Supabase Storage object." };
  }

  return { url };
}

function normalizedOrigin(value: unknown): string | null {
  const text = stringOrNull(value);
  if (!text) return null;

  try {
    const url = new URL(text);
    if (url.protocol !== "http:" && url.protocol !== "https:") return null;
    return url.origin;
  } catch (_) {
    return null;
  }
}

async function readResponseTextSnippet(
  response: Response,
  maxChars: number,
): Promise<string> {
  if (maxChars <= 0) return "";
  if (!response.body) {
    return truncateText(await response.text(), maxChars);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let text = "";

  while (text.length < maxChars) {
    const { done, value } = await reader.read();
    if (done) break;
    if (!value) continue;

    text += decoder.decode(value, { stream: true });
    if (text.length >= maxChars) {
      await reader.cancel();
      break;
    }
  }
  text += decoder.decode();

  return truncateText(text, maxChars);
}

function sanitizeUpstreamError(text: string, secrets: string[]): unknown {
  const trimmed = text.trim();
  if (!trimmed) return null;

  try {
    return sanitizeUpstreamErrorValue(JSON.parse(trimmed), secrets);
  } catch (_) {
    return redactSensitiveText(truncateText(trimmed, maxUpstreamErrorChars), secrets);
  }
}

function sanitizeUpstreamErrorValue(
  value: unknown,
  secrets: string[],
  depth = 0,
): unknown {
  if (typeof value === "string") {
    return redactSensitiveText(truncateText(value, maxUpstreamErrorChars), secrets);
  }
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (typeof value === "boolean" || value === null) return value;
  if (depth >= 5) return "[truncated]";

  if (Array.isArray(value)) {
    const result = value.slice(0, 10).map((item) =>
      sanitizeUpstreamErrorValue(item, secrets, depth + 1)
    );
    if (value.length > 10) result.push("[truncated]");
    return result;
  }

  if (!isRecord(value)) return null;

  const result: Record<string, unknown> = {};
  let count = 0;
  for (const [key, nestedValue] of Object.entries(value)) {
    if (count >= 20) {
      result.truncated = true;
      break;
    }
    result[key] = isSensitiveUpstreamErrorKey(key)
      ? "[redacted]"
      : sanitizeUpstreamErrorValue(nestedValue, secrets, depth + 1);
    count += 1;
  }
  return result;
}

function isSensitiveUpstreamErrorKey(key: string): boolean {
  const normalized = key.toLowerCase().replace(/[^a-z0-9]/g, "");
  return normalized.includes("apikey") ||
    normalized.includes("authorization") ||
    normalized.includes("bearer") ||
    normalized.includes("token") ||
    normalized.includes("secret") ||
    normalized.includes("password") ||
    normalized.includes("header") ||
    normalized.includes("base64") ||
    normalized.includes("image");
}

function redactSensitiveText(value: string, secrets: string[]): string {
  let redacted = value;
  for (const secret of secrets) {
    if (secret) redacted = redacted.split(secret).join("[redacted]");
  }
  return redacted
    .replace(/[A-Za-z0-9+/]{80,}={0,2}/g, "[redacted]")
    .replace(
      /(api[-_ ]?key|authorization|bearer)\s*[:=]\s*["']?[^"',\s}]+/gi,
      "$1: [redacted]",
    );
}

function truncateText(value: string, maxChars: number): string {
  return value.length > maxChars ? value.slice(0, maxChars) : value;
}
async function fetchWithTimeout(
  fetcher: FetchLike,
  input: RequestInfo | URL,
  init: RequestInit,
  timeoutMs: number,
): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetcher(input, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

async function readResponseBytes(
  response: Response,
  limit: number,
): Promise<Uint8Array> {
  const declaredLength = Number(response.headers.get("content-length"));
  if (Number.isFinite(declaredLength) && declaredLength > limit) {
    throw new ImageTooLargeError();
  }

  if (!response.body) {
    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.length > limit) throw new ImageTooLargeError();
    return bytes;
  }

  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let totalLength = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    if (!value) continue;

    totalLength += value.byteLength;
    if (totalLength > limit) {
      await reader.cancel();
      throw new ImageTooLargeError();
    }
    chunks.push(value);
  }

  const bytes = new Uint8Array(totalLength);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return bytes;
}

function isSupportedImage(bytes: Uint8Array): boolean {
  const isJpeg =
    bytes.length >= 3 &&
    bytes[0] === 0xff &&
    bytes[1] === 0xd8 &&
    bytes[2] === 0xff;
  const isPng =
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a;

  return isJpeg || isPng;
}

function bytesToBase64(bytes: Uint8Array): string {
  const chunkSize = 0x8000;
  let binary = "";
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(
      ...bytes.subarray(offset, offset + chunkSize),
    );
  }
  return btoa(binary);
}

function suggestionCount(value: Record<string, unknown>): number {
  const result = recordOrEmpty(value.result);
  const disease = recordOrEmpty(result.disease);
  return Array.isArray(disease.suggestions) ? disease.suggestions.length : 0;
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

function finiteNumberOrNull(value: unknown): number | null {
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : null;
  }
  if (typeof value !== "string" || value.trim().length === 0) return null;

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function numberOrStringOrNull(value: unknown): number | string | null {
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : null;
  }
  return typeof value === "string" ? stringOrNull(value) : null;
}

function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map(stringOrNull).filter(isNotNull);
}

function stringOrNull(value: unknown): string | null {
  if (typeof value !== "string" && typeof value !== "number") return null;
  const text = value.toString().trim();
  return text ? text : null;
}

function recordOrEmpty(value: unknown): Record<string, unknown> {
  return isRecord(value) ? value : {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isNotNull<T>(value: T | null): value is T {
  return value !== null;
}

class ImageTooLargeError extends Error {}
