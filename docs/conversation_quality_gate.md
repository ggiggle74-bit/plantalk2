# Conversation quality gate

CR-2M evaluates the existing dialogue stack without adding another runtime
engine or remote slot.

## Routing priorities

1. DB-authored intent replies
2. latest condition-memory replies
3. local casual conversation
4. the existing authenticated Gemini fallback
5. the existing fail-closed local fallback

Calling the plant by name is not, by itself, a greeting intent. The matcher
uses the current request's `plantName`; `무가리` is only an example and is not
hard-coded. Korean vocatives such as `해피야` and the common nickname form
`초록이` -> `초록아` are recognized. The remainder of the message still
determines the route. For example, `무가리야 오늘 어때?` stays local, while
`무가리야 공룡은 왜 멸종했어?` uses the API route.

## Acceptance scenarios

| User message | Expected route | Expected behavior |
| --- | --- | --- |
| `안녕` | local casual | short authored or local greeting |
| `무가리야` | local casual | acknowledges the plant address |
| `무가리야 오늘 어때?` | local casual | casual plant response |
| `최근 상태가 어땠어?` | condition memory | reflects the latest stored observation |
| `무가리야 공룡은 왜 멸종했어?` | API | direct, age-appropriate factual answer |
| `안녕, 공룡은 왜 멸종했어?` | API | knowledge intent wins over the greeting word |
| `무가리야 나 오늘 학교에서 속상한 일이 있었어` | API | empathetic response rather than a generic greeting |
| `그건 왜 그런 거야?` | API | uses only the immediately previous complete turn |

## Quality constraints

- no fixed suffix such as `작게 말해볼게`
- no factual avoidance merely because the speaker is a plant
- no full-history transmission or persistence
- no condition-memory object or plant database ID sent to Gemini
- no additional runtime processor, provider, or composition-root wiring

Run the focused router and controller tests before the full Flutter suite.
Manual laptop testing is sufficient for reply content; mobile remains required
for keyboard, lifecycle, camera, and device-session checks.
