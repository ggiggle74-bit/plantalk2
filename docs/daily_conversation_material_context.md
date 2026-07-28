# Daily conversation material context

`DailyConversationMaterialContext` is the bounded, session-facing projection of
the daily keyword document. It gives the local conversation engine safe material
without making the collector, Supabase, or Gemini a runtime reply processor.

## Boundary

- `DailyKeywordSource` loads one remote-or-local daily keyword document.
- `DailyConversationMaterialProjector` accepts only same-day, supported,
  non-blocked entries with complete hints and a fit score of at least `0.60`.
- Duplicate keywords are removed while source priority is preserved.
- At most eight materials are exposed.
- `DailyConversationMaterialProvider` fails closed with `null`.
- Raw search documents, URLs, and article text never enter the app context.

The context carries material only: keyword, short hint, plant-facing hint, tone,
scores, category, and age targeting. It does not select a reply, track usage,
apply character tone, call Gemini, or persist conversation history.

## Follow-up CR

CR-2P will carry this context into the local casual engine and add a bounded
usage ledger so recent materials and replies are not repeated. The existing
`DailyOpeningContext` remains first-turn-only and separate from the session
material pool.
