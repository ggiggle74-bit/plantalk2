import { corsHeaders } from "../_shared/cors.ts";

export type FetchLike = (
  input: RequestInfo | URL,
  init?: RequestInit,
) => Promise<Response>;

type EnvReader = (name: string) => string | undefined;
type Logger = Pick<Console, "info" | "warn">;
type Clock = () => Date;
type ObservationIdFactory = () => string;

export type GeminiDefaultObserveDependencies = {
  getEnv: EnvReader;
  fetcher?: FetchLike;
  logger?: Logger;
  now?: Clock;
  createObservationId?: ObservationIdFactory;
};

type GeminiDefaultObserveRequest = {
  imageUrl?: unknown;
};

type SanitizedDefaultObservation = {
  image_quality: string;
  observation_state: string;
  evidence_tags: string[];
};

type ModelObservationSanitization = {
  observation: SanitizedDefaultObservation;
  contractValid: boolean;
};

export const geminiDefaultObservationModel = "gemini-3.1-flash-lite";

const geminiInteractionsEndpoint =
  "https://generativelanguage.googleapis.com/v1/interactions";
const maxImageBytes = 10 * 1024 * 1024;
const imageFetchTimeoutMs = 15_000;
const geminiFetchTimeoutMs = 30_000;
const publicStoragePathPrefix = "/storage/v1/object/public/";

const imageQualities = ["usable", "limited", "unusable"] as const;
const observationStates = [
  "stable_appearance",
  "growth_positive",
  "new_leaf_observed",
  "flowering_observed",
  "visible_concern",
  "uncertain",
] as const;
const evidenceTags = [
  "stable_foliage",
  "new_growth",
  "new_leaf",
  "flowering",
  "visible_discoloration",
  "visible_wilting",
  "visible_damage",
  "leaf_drop",
  "image_unclear",
] as const;

const allowedImageQualities = new Set<string>(imageQualities);
const allowedObservationStates = new Set<string>(observationStates);
const allowedEvidenceTags = new Set<string>(evidenceTags);

const systemInstruction = [
  "You are a narrowly scoped visual observation classifier for a houseplant app.",
  "Observe only appearance that is directly visible in the single supplied image.",
  "Do not diagnose plant health, disease, pests, watering, light, soil, roots, repotting, treatment, chemical use, or causes.",
  "Do not infer facts that are not directly visible.",
  "Use visible_concern when a visible change may need a separate health assessment.",
  "Use uncertain when image quality or ambiguity prevents a stable observation.",
  "Return only the fields required by the response schema.",
].join(" ");

const observationPrompt = [
  "Classify this one plant photo as a non-diagnostic default-state observation.",
  "Set image_quality to usable only when the relevant visible plant area is clear enough to observe.",
  "For stable_appearance include stable_foliage.",
  "For growth_positive include new_growth.",
  "For new_leaf_observed include new_leaf.",
  "For flowering_observed include flowering.",
  "When discoloration, wilting, damage, or leaf drop is visible, use visible_concern and include every matching concern tag.",
  "When the image is unclear, include image_unclear and use limited or unusable quality.",
  "Never output a diagnosis, cause, treatment, care instruction, or confidence score.",
].join(" ");

const responseFormat = {
  type: "text",
  mime_type: "application/json",
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      image_quality: {
        type: "string",
        enum: imageQualities,
      },
      observation_state: {
        type: "string",
        enum: observationStates,
      },
      evidence_tags: {
        type: "array",
        maxItems: 4,
        items: {
          type: "string",
          enum: evidenceTags,
        },
      },
    },
    required: ["image_quality", "observation_state", "evidence_tags"],
  },
} as const;

export function createGeminiDefaultObserveHandler(
  dependencies: GeminiDefaultObserveDependencies,
): (request: Request) => Promise<Response> {
  const fetcher = dependencies.fetcher ?? fetch;
  const logger = dependencies.logger ?? console;
  const now = dependencies.now ?? (() => new Date());
  const createObservationId = dependencies.createObservationId ??
    (() => crypto.randomUUID());

  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return jsonResponse({ error: "Method not allowed." }, 405);
    }

    const apiKey = stringOrNull(dependencies.getEnv("GEMINI_API_KEY"));
    if (!apiKey) {
      return jsonResponse(
        {
          error: "GEMINI_API_KEY Supabase Edge Function secret is missing.",
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

    let body: GeminiDefaultObserveRequest;
    try {
      const decoded: unknown = await request.json();
      if (!isRecord(decoded)) {
        return jsonResponse(
          { error: "Request body must be a JSON object." },
          400,
        );
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
          redirect: "error",
        },
        imageFetchTimeoutMs,
      );
    } catch (_) {
      logger.warn("gemini-default-observe image download failed");
      return jsonResponse({ error: "Plant image download failed." }, 502);
    }

    if (!imageResponse.ok) {
      logger.warn("gemini-default-observe image download returned an error", {
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

      logger.warn("gemini-default-observe image body could not be read");
      return jsonResponse({ error: "Plant image download failed." }, 502);
    }

    if (imageBytes.length === 0) {
      return jsonResponse({ error: "Plant image is empty." }, 400);
    }

    const imageMimeType = supportedImageMimeType(imageBytes);
    if (!imageMimeType) {
      return jsonResponse({ error: "Plant image must be JPEG or PNG." }, 400);
    }

    const geminiRequest = {
      model: geminiDefaultObservationModel,
      store: false,
      system_instruction: systemInstruction,
      input: [
        { type: "text", text: observationPrompt },
        {
          type: "image",
          data: bytesToBase64(imageBytes),
          mime_type: imageMimeType,
        },
      ],
      response_format: responseFormat,
      generation_config: {
        temperature: 0,
        thinking_level: "minimal",
        thinking_summaries: "none",
        max_output_tokens: 160,
        tool_choice: "none",
      },
    };

    let geminiResponse: Response;
    try {
      geminiResponse = await fetchWithTimeout(
        fetcher,
        geminiInteractionsEndpoint,
        {
          method: "POST",
          headers: {
            accept: "application/json",
            "Content-Type": "application/json",
            "Cache-Control": "no-store",
            "x-goog-api-key": apiKey,
          },
          body: JSON.stringify(geminiRequest),
        },
        geminiFetchTimeoutMs,
      );
    } catch (_) {
      logger.warn("gemini-default-observe upstream request failed");
      return jsonResponse(
        { error: "Gemini default observation request failed." },
        502,
      );
    }

    const responseText = await geminiResponse.text();
    if (!geminiResponse.ok) {
      logger.warn("gemini-default-observe upstream returned an error", {
        status: geminiResponse.status,
      });
      return jsonResponse(
        {
          error: "Gemini default observation request failed.",
          status: geminiResponse.status,
        },
        502,
      );
    }

    let interaction: Record<string, unknown>;
    try {
      const decoded: unknown = JSON.parse(responseText);
      if (!isRecord(decoded)) {
        throw new TypeError("Interaction response must be an object.");
      }
      interaction = decoded;
    } catch (_) {
      logger.warn("gemini-default-observe returned invalid interaction JSON");
      return jsonResponse(
        { error: "Gemini default observation returned invalid JSON." },
        502,
      );
    }

    if (interaction.status !== "completed") {
      logger.warn("gemini-default-observe did not complete", {
        status: stringOrNull(interaction.status),
      });
      return jsonResponse(
        { error: "Gemini default observation did not complete." },
        502,
      );
    }

    const modelOutputText = extractModelOutputText(interaction);
    if (!modelOutputText) {
      logger.warn("gemini-default-observe returned no model output text");
      return jsonResponse(
        { error: "Gemini default observation returned no output." },
        502,
      );
    }

    let modelOutput: unknown;
    try {
      modelOutput = JSON.parse(modelOutputText);
    } catch (_) {
      modelOutput = null;
    }

    const sanitized = sanitizeModelObservation(modelOutput);
    const usage = recordOrEmpty(interaction.usage);
    logger.info("gemini-default-observe succeeded", {
      model: geminiDefaultObservationModel,
      contractValid: sanitized.contractValid,
      totalInputTokens: finiteIntegerOrNull(usage.total_input_tokens),
      totalOutputTokens: finiteIntegerOrNull(usage.total_output_tokens),
    });

    return jsonResponse({
      observation_id: nonEmptyObservationId(createObservationId),
      observed_at: observedAtIso(now),
      ...sanitized.observation,
    });
  };
}

function sanitizeModelObservation(
  value: unknown,
): ModelObservationSanitization {
  if (!isRecord(value)) {
    return invalidObservation();
  }

  const imageQuality = strictString(value.image_quality);
  const observationState = strictString(value.observation_state);
  const rawTags = value.evidence_tags;

  if (
    imageQuality === null ||
    !allowedImageQualities.has(imageQuality) ||
    observationState === null ||
    !allowedObservationStates.has(observationState) ||
    !Array.isArray(rawTags) ||
    rawTags.length > 4
  ) {
    return invalidObservation();
  }

  const tags: string[] = [];
  for (const value of rawTags) {
    const tag = strictString(value);
    if (tag === null || !allowedEvidenceTags.has(tag)) {
      return invalidObservation();
    }
    if (!tags.includes(tag)) {
      tags.push(tag);
    }
  }

  return {
    observation: {
      image_quality: imageQuality,
      observation_state: observationState,
      evidence_tags: tags,
    },
    contractValid: true,
  };
}

function invalidObservation(): ModelObservationSanitization {
  return {
    observation: {
      image_quality: "unusable",
      observation_state: "uncertain",
      evidence_tags: ["image_unclear"],
    },
    contractValid: false,
  };
}

function extractModelOutputText(
  interaction: Record<string, unknown>,
): string | null {
  const steps = interaction.steps;
  if (!Array.isArray(steps)) {
    return null;
  }

  for (let index = steps.length - 1; index >= 0; index--) {
    const step = steps[index];
    if (!isRecord(step) || step.type !== "model_output") {
      continue;
    }

    const content = step.content;
    if (!Array.isArray(content)) {
      continue;
    }

    const text = content
      .filter(isRecord)
      .filter((block) => block.type === "text")
      .map((block) => strictString(block.text))
      .filter((value): value is string => value !== null)
      .join("");

    if (text.trim()) {
      return text;
    }
  }

  return null;
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
    return {
      error: "imageUrl must point to a public Supabase Storage object.",
    };
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

function supportedImageMimeType(bytes: Uint8Array): string | null {
  const isJpeg = bytes.length >= 3 &&
    bytes[0] === 0xff &&
    bytes[1] === 0xd8 &&
    bytes[2] === 0xff;
  if (isJpeg) return "image/jpeg";

  const isPng = bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a;
  return isPng ? "image/png" : null;
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

function nonEmptyObservationId(factory: ObservationIdFactory): string {
  return stringOrNull(factory()) ?? crypto.randomUUID();
}

function observedAtIso(clock: Clock): string {
  const value = clock();
  return Number.isFinite(value.getTime())
    ? value.toISOString()
    : new Date().toISOString();
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

function finiteIntegerOrNull(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return Math.trunc(value);
}

function strictString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function stringOrNull(value: unknown): string | null {
  const text = value?.toString().trim();
  return text ? text : null;
}

function recordOrEmpty(value: unknown): Record<string, unknown> {
  return isRecord(value) ? value : {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

class ImageTooLargeError extends Error {}
