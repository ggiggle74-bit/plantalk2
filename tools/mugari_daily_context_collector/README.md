# Mugari Daily Context Collector

This directory contains the standalone, pure-Dart side of the Plantalk daily
conversation-material pipeline. It is intentionally separate from the Flutter
application runtime.

## Completed scope

### CR-2A — app-facing context contract

CR-2A defines `daily-keyword-context/v1` before any search API, storage, or
scheduler is connected.

Included:

- `DailyKeywordCandidate`
- optional `targetAgeBands`
- `DailyKeywordContextDocument`
- deterministic JSON encoding and decoding
- executable contract validation
- JSON Schema
- a checked-in valid payload
- a CLI that validates a future collector output file

### CR-2B — deterministic search planning

CR-2B adds the provider-neutral planning layer used before a future search
client is called.

Included:

- `DailyQueryPlanRequest`
- `DailySearchQuery`
- `DailyQueryPlan`
- `DailyQueryPlanner`
- `SearchDocument`
- a query-plan preview CLI

The planner always creates six safe general searches for weather, nature,
season, parks, environment, and culture. A local context may add one region
query. When age bands are explicitly requested, at most two neutral audience
discovery searches are selected deterministically by date. This keeps the
daily request count bounded while rotating coverage across age bands.

The planner does not search broad news, real-time issues, politics, crime,
accidents, or war. It creates query instructions only; it performs no network
request.

## Not included yet

- Kakao/Daum Search API calls
- weather or public-data API calls
- RSS or HTML crawling
- keyword extraction or scoring from search documents
- Supabase writes
- scheduling
- Plantalk runtime activation
- age-band weighting or age-aware final selection

## Daily keyword contract

A ready-to-store document uses schema version:

```text
daily-keyword-context/v1
```

The top-level document contains:

- date
- locale
- region code
- generated timestamp
- collector source version
- zero to eight keyword candidates

Each accepted candidate contains the fields already expected by Plantalk:

- `type`
- `keyword`
- `hint`
- optional `category`
- optional `relevanceScore`
- `plantHint`
- `tone`
- `fitScore`
- one to four `conversationAngles`
- optional `targetAgeBands`

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

An absent or empty `targetAgeBands` list means the material is suitable for all
age bands. Age suitability is ranking metadata, not a hard stereotype. The
collector does not store birth dates or exact ages, and Plantalk must not infer
age from conversation text.

Allowed candidate types:

```text
weather
calendar
seasonal
safe_issue
```

Allowed tones:

```text
gentle
calm
bright
cautious
```

A ready-to-store candidate must have `fitScore >= 0.60`.

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

The validator CLI reports the schema version, candidate count, locale, and
region. The planner CLI prints deterministic JSON containing the bounded query
plan.

## Planned sequence

1. Contract, validator, and optional age bands — CR-2A
2. Search document model and deterministic query planner — CR-2B
3. Kakao/Daum Search client with fixture-based tests — CR-2C
4. Keyword extraction, safety filtering, scoring, and diversity limits
5. Weather, calendar, holiday, safe-issue, and optional region sources
6. Supabase repository and idempotent daily upsert
7. Scheduler activation
8. Plantalk remote source activation with local fallback
9. Age-aware ranking as a separate policy stage

The existing Flutter collector can later become an operator review screen. It
must not hold production search secrets or run the scheduled collector.
