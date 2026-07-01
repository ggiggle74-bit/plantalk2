import { corsHeaders } from "../_shared/cors.ts";

type PlantNetIdentifyRequest = {
  imageBase64?: unknown;
  filename?: unknown;
  contentType?: unknown;
  project?: unknown;
  lang?: unknown;
  nbResults?: unknown;
};

const supportedContentTypes = new Set(["image/jpeg", "image/png"]);
const supportedLanguages = new Set([
  "ar",
  "cs",
  "de",
  "el",
  "en",
  "es",
  "fi",
  "fr",
  "he",
  "id",
  "it",
  "nl",
  "pl",
  "pt",
  "ru",
  "sk",
  "tr",
  "uk",
  "zh",
]);

Deno.serve(async (request) => {
  const requestStartedAt = performance.now();
  console.info("plantnet-identify request received", {
    method: request.method,
    totalElapsedMs: 0,
  });

  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const apiKey = Deno.env.get("PLANTNET_API_KEY")?.trim();
  if (!apiKey) {
    return jsonResponse(
      { error: "PLANTNET_API_KEY Supabase Edge Function secret is missing." },
      500,
    );
  }

  let body: PlantNetIdentifyRequest;
  const bodyParseStartedAt = performance.now();
  try {
    console.info("plantnet-identify before request JSON", {
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    body = await request.json();
    console.info("plantnet-identify request JSON parsed", {
      elapsedMs: elapsedMs(bodyParseStartedAt),
    });
  } catch (_) {
    console.warn("plantnet-identify request JSON parse failed", {
      elapsedMs: elapsedMs(bodyParseStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    return jsonResponse({ error: "Request body must be valid JSON." }, 400);
  }

  const imageBase64 = stringOrNull(body.imageBase64);
  if (!imageBase64) {
    return jsonResponse({ error: "imageBase64 is required." }, 400);
  }

  const contentType = normalizeContentType(body.contentType);
  if (!contentType) {
    return jsonResponse(
      { error: "contentType must be image/jpeg or image/png." },
      400,
    );
  }

  const project = normalizeProject(body.project);
  const lang = normalizeLanguage(body.lang);
  const nbResults = clampNumber(body.nbResults, 1, 10, 5);
  const filename = normalizeFilename(body.filename, contentType);
  const diagnosticMetadata = {
    imageBase64Length: imageBase64.length,
    contentType,
    filename,
    project,
    lang,
    nbResults,
  };

  let imageBytes: Uint8Array;
  const base64DecodeStartedAt = performance.now();
  try {
    imageBytes = base64ToBytes(imageBase64);
    console.info("plantnet-identify image base64 decoded", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      elapsedMs: elapsedMs(base64DecodeStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
  } catch (_) {
    console.warn("plantnet-identify image base64 decode failed", {
      ...diagnosticMetadata,
      elapsedMs: elapsedMs(base64DecodeStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    return jsonResponse({ error: "imageBase64 must be valid base64." }, 400);
  }

  if (imageBytes.length === 0) {
    return jsonResponse({ error: "imageBase64 is empty." }, 400);
  }

  const plantNetUrl = new URL(
    `https://my-api.plantnet.org/v2/identify/${encodeURIComponent(project)}`,
  );
  plantNetUrl.searchParams.set("api-key", apiKey);
  plantNetUrl.searchParams.set("lang", lang);
  plantNetUrl.searchParams.set("nb-results", nbResults.toString());
  plantNetUrl.searchParams.set("include-related-images", "false");

  const formDataStartedAt = performance.now();
  let formData: FormData;
  try {
    formData = new FormData();
    const imageBlobPart = imageBytes as unknown as BlobPart;
    formData.append(
      "images",
      new File([imageBlobPart], filename, { type: contentType }),
    );
    formData.append("organs", "auto");
    console.info("plantnet-identify form data created", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      elapsedMs: elapsedMs(formDataStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
  } catch (error) {
    console.warn("plantnet-identify form data creation failed", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      elapsedMs: elapsedMs(formDataStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    throw error;
  }

  const upstreamFetchStartedAt = performance.now();
  let plantNetResponse: Response;
  try {
    console.info("plantnet-identify upstream fetch started", {
      project,
      lang,
      nbResults,
      imageBytesLength: imageBytes.length,
      contentType,
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    plantNetResponse = await fetch(plantNetUrl, {
      method: "POST",
      body: formData,
      headers: { accept: "application/json" },
    });
    console.info("plantnet-identify upstream fetch completed", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      status: plantNetResponse.status,
      elapsedMs: elapsedMs(upstreamFetchStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
  } catch (error) {
    console.warn("plantnet-identify upstream fetch failed", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      elapsedMs: elapsedMs(upstreamFetchStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    throw error;
  }

  const responseTextStartedAt = performance.now();
  const responseText = await plantNetResponse.text();
  console.info("plantnet-identify upstream response body read", {
    ...diagnosticMetadata,
    imageBytesLength: imageBytes.length,
    status: plantNetResponse.status,
    elapsedMs: elapsedMs(responseTextStartedAt),
    totalElapsedMs: elapsedMs(requestStartedAt),
  });
  if (!plantNetResponse.ok) {
    console.warn("plantnet-identify upstream failed", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      status: plantNetResponse.status,
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    return jsonResponse(
      {
        error: "Pl@ntNet identification request failed.",
        status: plantNetResponse.status,
      },
      502,
    );
  }

  let decoded: Record<string, unknown>;
  const responseJsonParseStartedAt = performance.now();
  try {
    decoded = JSON.parse(responseText);
    console.info("plantnet-identify upstream JSON parsed", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      elapsedMs: elapsedMs(responseJsonParseStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
  } catch (_) {
    console.warn("plantnet-identify upstream JSON parse failed", {
      ...diagnosticMetadata,
      imageBytesLength: imageBytes.length,
      elapsedMs: elapsedMs(responseJsonParseStartedAt),
      totalElapsedMs: elapsedMs(requestStartedAt),
    });
    return jsonResponse(
      { error: "Pl@ntNet returned invalid JSON." },
      502,
    );
  }

  const results = Array.isArray(decoded.results)
    ? decoded.results.map(normalizeResult).filter((result) => result !== null)
    : [];

  console.info("plantnet-identify succeeded", {
    ...diagnosticMetadata,
    imageBytesLength: imageBytes.length,
    status: plantNetResponse.status,
    resultCount: results.length,
    totalElapsedMs: elapsedMs(requestStartedAt),
  });

  return jsonResponse({
    bestMatch: stringOrNull(decoded.bestMatch),
    remainingIdentificationRequests: decoded.remainingIdentificationRequests,
    results,
  });
});

function elapsedMs(startedAt: number): number {
  return Math.round(performance.now() - startedAt);
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function normalizeResult(value: unknown): Record<string, unknown> | null {
  if (!isRecord(value)) return null;

  const species = isRecord(value.species) ? value.species : {};
  return {
    score: value.score,
    bestMatch: stringOrNull(value.bestMatch),
    gbif: normalizeIdObject(value.gbif),
    powo: normalizeIdObject(value.powo),
    species: {
      scientificName: stringOrNull(species.scientificName),
      scientificNameWithoutAuthor: stringOrNull(
        species.scientificNameWithoutAuthor,
      ),
      commonNames: Array.isArray(species.commonNames)
        ? species.commonNames.map(stringOrNull).filter((name) => name !== null)
        : [],
    },
  };
}

function normalizeIdObject(value: unknown): Record<string, unknown> {
  if (!isRecord(value)) return {};
  return { id: stringOrNull(value.id) };
}

function normalizeContentType(value: unknown): string | null {
  const contentType = stringOrNull(value)?.toLowerCase().split(";")[0].trim();
  return contentType && supportedContentTypes.has(contentType)
    ? contentType
    : null;
}

function normalizeProject(value: unknown): string {
  const project = stringOrNull(value) ?? "all";
  return /^[A-Za-z0-9_-]+$/.test(project) ? project : "all";
}

function normalizeLanguage(value: unknown): string {
  const language = (stringOrNull(value) ?? "ko")
    .toLowerCase()
    .split(/[-_]/)[0]
    .trim();

  return supportedLanguages.has(language) ? language : "en";
}

function normalizeFilename(value: unknown, contentType: string): string {
  const filename = stringOrNull(value);
  if (filename) return filename;
  return contentType === "image/png" ? "plant.png" : "plant.jpg";
}

function clampNumber(
  value: unknown,
  min: number,
  max: number,
  fallback: number,
): number {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(max, Math.max(min, Math.trunc(parsed)));
}

function base64ToBytes(base64: string): Uint8Array {
  const normalized = base64.includes(",")
    ? base64.split(",").pop() ?? ""
    : base64;
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index++) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

function stringOrNull(value: unknown): string | null {
  const text = value?.toString().trim();
  return text ? text : null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
