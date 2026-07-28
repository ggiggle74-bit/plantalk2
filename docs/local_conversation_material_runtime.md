# Local conversation material runtime

CR-2P connects the projected daily material pool to local casual conversation.
It does not change the single route decision: recognized casual conversation
stays local, while knowledge and complex exceptions continue to use Gemini.

## Runtime ownership

- The app coordinator loads the daily source once per chat opening.
- The same source result produces a first-turn `DailyOpeningContext` and a
  session-scoped `DailyConversationMaterialContext`.
- `ChatPanel` owns one in-memory `ConversationUsageLedger`.
- The local engine reads and records that ledger.
- Nothing is persisted to `plant_memories` or sent to Gemini.

## Repetition guard

- a material keyword cools down for three local turns
- a reply template cools down for four local turns
- the opening keyword enters the same material cooldown
- tracked material and reply keys are bounded in memory
- when every material is cooling down, the engine uses a rotating plain local
  reply instead of calling an external API

The ledger is discarded when the chat panel closes. Character mood and
friendship-specific composition remain a later bounded CR.
