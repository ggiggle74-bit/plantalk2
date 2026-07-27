# Conversation quality gate

CR-2M evaluates the existing dialogue stack without adding another runtime
engine or remote slot.

## Routing priorities

One pure intent decision is made before any reply source runs.

1. explicit condition-history questions stay local
2. explicit knowledge or complex questions use the authenticated Gemini route
3. recognized local casual situations may use an approved DB-authored reply
4. a DB miss on a local casual situation uses the local casual engine
5. provider failures use the existing fail-closed local fallback

A greeting word, positive word, or overdue watering state must not intercept a
knowledge question. An explicit recent-photo question without condition memory
returns a local photo-check invitation and must not call the API.

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
| `안녕, 공룡은 왜 멸종했어?` | API | skips greeting DB replies |
| `우주의 크기를 설명해줘` with overdue watering | API | skips thirsty DB replies |
| `최근 사진에서 상태가 어땠어?` without memory | condition memory | returns a local seven-day photo-check invitation |

## Quality constraints

- no fixed suffix such as `작게 말해볼게`
- no factual avoidance merely because the speaker is a plant
- no full-history transmission or persistence
- no condition-memory object or plant database ID sent to Gemini
- no additional runtime processor, provider, or composition-root wiring
- no DB lookup before an API route is finalized
- no API call for an explicit condition-history question without memory

Run the focused router and controller tests before the full Flutter suite.
Manual laptop testing is sufficient for reply content; mobile remains required
for keyboard, lifecycle, camera, and device-session checks.
