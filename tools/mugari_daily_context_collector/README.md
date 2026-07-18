# Mugari Daily Context Collector

This directory contains the standalone, pure-Dart side of the Plantalk daily
conversation-material pipeline. It is intentionally separate from the Flutter
application runtime.

## Completed scope

### CR-2A — app-facing context contract

CR-2A defines `daily-keyword-context/v1`, deterministic JSON models,
validation, JSON Schema, age-band metadata, and a checked-in valid payload.

### CR-2B — deterministic search planning

CR-2B adds `DailyQueryPlanner`, bounded safe query plans, optional region and
age-band discovery queries, and the normalized `SearchDocument` model.

The planner creates six general searches for weather, nature, season, parks,
environment, and culture. A local context may add one region query. At most two
neutral age-band queries rotate by date. Broad news, real-time issues, politics,
crime, accidents, and war are not searched.

### CR-2C — injectable Kakao/Daum search boundary

CR-2C adds `DaumSearchClient` for the documented web and blog search request
and response shapes.

Included:

- `/v2/search/web` and `/v2/search/blog` request construction
- injected REST API key and injected HTTP transport
- `KakaoAK` authorization header construction
- provider page, size, and sort validation
- response metadata and document parsing
- conversion into provider-neutral `SearchDocument` values
- URL de-duplication
- sanitized provider errors
- checked-in web and blog fixtures

The client does not read environment variables, own an HTTP package, print or
store the key, or make a live request by itself. A later server-side adapter
will inject the production transport and secret.

### CR-2D — whitelist extraction and ranking

CR-2D adds `DailyKeywordExtractionPolicy`. It accepts normalized
`SearchDocument` values and produces at most eight v1 candidates.

The policy:

- extracts only the checked-in weather, season, and safe-issue whitelist
- rejects a complete document when blocked political, crime, war, accident, or
  disaster terms are present
- rejects stale and implausibly future-dated documents
- combines catalog fit, query priority, and freshness into relevance scoring
- keeps the highest-scored duplicate
- prefers a specific term such as `장맛비` over the nested `비`
- limits each candidate type to three entries
- preserves optional age-band discovery metadata
- returns an empty result instead of inventing an unrecognized keyword

### CR-2E — fail-safe source composition

CR-2E adds a common `DailyCandidateSource` boundary, an immutable snapshot
source, a deterministic Korean calendar/season source, and
`DailyKeywordContextAssembler`.

The assembler isolates individual source failures, rejects candidates that do
not satisfy the v1 contract, keeps the strongest normalized duplicate, applies
the eight-candidate and per-type limits again, and produces a final validated
`DailyKeywordContextDocument`. Empty or partially failed input remains a valid
document.

## Not included yet

- live HTTP transport or production Kakao key
- weather or public-data API calls
- RSS or HTML crawling
- Supabase writes
- scheduling
- Plantalk runtime activation
- age-band weighting or age-aware final selection

## Daily keyword contract

A ready-to-store document uses schema version:

```text
daily-keyword-context/v1
```

The top-level document contains date, locale, region code, generated timestamp,
collector source version, and zero to eight keyword candidates.

Each candidate contains `type`, `keyword`, `hint`, optional `category`,
optional `relevanceScore`, `plantHint`, `tone`, `fitScore`, one to four
`conversationAngles`, and optional `targetAgeBands`.

`conversationAngles` are reusable discussion directions, not final Mugari
lines. The Plantalk conversation engine remains responsible for character
voice and final sentence composition.

Allowed age bands:

```text
10s
20s
30s
40s
50s
60s_plus
```

An absent or empty `targetAgeBands` list means the material is suitable for
all age bands. Age suitability is ranking metadata, not a hard stereotype. The
collector does not store birth dates or exact ages, and Plantalk must not infer
age from conversation text.

Allowed candidate types are `weather`, `calendar`, `seasonal`, and
`safe_issue`. Allowed tones are `gentle`, `calm`, `bright`, and
`cautious`. A ready-to-store candidate must have `fitScore >= 0.60`.

## Commands

Run these commands from this directory:

```powershell
dart pub get
dart test
dart analyze
dart run bin/mugari_daily_context_collector.dart example/daily_keyword_context.json
dart run bin/plan_daily_queries.dart 2026-07-18 ko-KR `
  --region-code=KR-11 --region-label=서울 `
  --age-bands=10s,20s,30s,40s,50s,60s_plus
```

## Planned sequence

1. Contract, validator, and optional age bands — CR-2A
2. Search document model and deterministic query planner — CR-2B
3. Kakao/Daum Search client with fixture-based tests — CR-2C
4. Keyword extraction, safety filtering, scoring, and diversity limits — CR-2D
5. Calendar/season source and fail-safe source composition — CR-2E
6. Weather, holiday, safe-issue, and optional region adapters
7. Supabase repository and idempotent daily upsert
8. Scheduler activation
9. Plantalk remote source activation with local fallback
10. Age-aware ranking as a separate policy stage

The existing Flutter collector can later become an operator review screen. It
must not hold production search secrets or run the scheduled collector.
