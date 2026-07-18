# Mugari Daily Context Collector

This directory contains the standalone, pure-Dart side of the Plantalk daily
conversation-material pipeline. It is intentionally separate from the Flutter
application runtime.

## CR-2A scope

CR-2A fixes the app-facing JSON contract before any search API, crawler,
storage, or scheduler is connected.

Included now:

- `DailyKeywordCandidate`
- `DailyKeywordContextDocument`
- deterministic JSON encoding and decoding
- contract validation
- JSON Schema
- a valid example payload
- a CLI that validates a future collector output file

Not included yet:

- Kakao/Daum Search API calls
- weather or public-data API calls
- RSS or HTML crawling
- Supabase writes
- scheduling
- Plantalk runtime activation

## Contract

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

It also contains one to four `conversationAngles`. These are short, reusable
ways to discuss the same material. They are not final Mugari dialogue lines.
The conversation engine remains responsible for character voice and final
sentence composition.

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
```

A valid example reports the schema version, candidate count, locale, and region.
Invalid input exits with a non-zero code and prints every contract violation.

## Planned sequence

1. Contract and validator — CR-2A
2. Search document model and deterministic query planner
3. Kakao/Daum Search client with fixture-based tests
4. Keyword extraction, safety filtering, scoring, and diversity limits
5. Weather, calendar, holiday, safe-issue, and optional region sources
6. Supabase repository and idempotent daily upsert
7. Scheduler activation
8. Plantalk remote source activation with local fallback

The existing Flutter collector can later become an operator review screen. It
must not hold production search secrets or run the scheduled collector.
