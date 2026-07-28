# Character tone context

CR-2Q connects the character state already stored on a plant to local casual
conversation. It does not add another runtime processor.

## Runtime flow

- `main.dart` resolves the selected plant's stored mood and friendship.
- `ChatPanel` forwards those values without interpreting them.
- `ChatPanelConversationController` carries them into one
  `ConversationRequest`.
- `LocalCasualConversationEngine` applies
  `PlantCharacterToneComposer` exactly once.
- DB-authored replies, condition-memory replies, and Gemini replies are not
  passed through the composer again.

## Behavior

- The current plant name is used; no runtime reply is tied to the name
  "무가리".
- Korean subject particles are selected from the final syllable of the current
  plant name.
- Shy, cheerful, and calm/tired mood families alter the opening of a local
  sentence instead of appending a fixed personality suffix.
- A high friendship score can add a name-aware relationship opening at a
  bounded checkpoint. It is intentionally not added to every reply.
- Neutral or unknown state leaves the selected local reply unchanged.

Species-specific personality archetypes remain outside this CR so that mood,
relationship, and species do not become competing reply processors.
