# Gemini 기본 상태 관찰 서버 게이트웨이 (G-1B)

결정일: 2026-06-24

참고한 공식 문서:

- https://ai.google.dev/gemini-api/docs/interactions-overview
- https://ai.google.dev/api/interactions-api-v1
- https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite
- https://ai.google.dev/gemini-api/docs/structured-output
- https://ai.google.dev/gemini-api/docs/image-understanding

## 1. 목적

G-1B는 G-1A에서 확정한 `default_observation` 계약 앞에 서버 전용 Gemini
게이트웨이를 추가한다.

이 단계에서는 Supabase Edge Function이 공개 Supabase Storage 사진을 내려받아
Gemini에 전달하고, 구조화 출력에서 G-1A가 허용한 세 필드만 정리해 반환한다.

Flutter 런타임에는 아직 연결하지 않는다. 따라서 앱 실행 중 Gemini 호출, 비용
발생, 기존 condition-check 흐름 변경은 없다.

## 2. API와 모델 결정

- API: 안정 버전 Interactions API
- endpoint: `POST https://generativelanguage.googleapis.com/v1/interactions`
- model: `gemini-3.1-flash-lite`
- state: `store: false`
- output: `response_format` JSON Schema
- thinking: `minimal`
- tools: 사용하지 않음

`gemini-3.1-flash-lite`는 이미지 입력과 구조화 출력을 지원하는 안정 모델이며,
이번의 제한된 분류·추출 작업에 맞춰 선택한다. 모델 교체는 Edge Function 내부
상수 변경으로만 수행하고 Flutter 계약에는 영향을 주지 않는다.

## 3. 이번 단계 범위

포함:

- `gemini-default-observe` Supabase Edge Function
- 서버 전용 `GEMINI_API_KEY`
- 같은 Supabase 프로젝트의 공개 Storage URL 검증
- JPEG/PNG 다운로드와 magic-byte 검증
- 10 MiB 이미지 상한
- Gemini Interactions API용 제한 프롬프트
- G-1A enum만 포함하는 JSON Schema
- gateway가 생성하는 `observation_id`와 `observed_at`
- raw provider payload를 노출하지 않는 응답 정리
- 외부 네트워크를 사용하지 않는 handler 단위 테스트

제외:

- Flutter adapter
- `main.dart` runtime wiring
- 자동 Gemini 호출
- DB schema 또는 `PlantService` 변경
- 관찰 결과 memory 저장 방식 변경
- Kindwise adapter 또는 `plant-health-assess` 변경
- 실제 Gemini key 등록·배포·실사진 호출

## 4. 클라이언트 요청 계약

Edge Function 요청:

```json
{
  "imageUrl": "https://<project>.supabase.co/storage/v1/object/public/plant-photos/..."
}
```

허용 조건:

- 절대 `http` 또는 `https` URL
- `SUPABASE_URL`과 동일한 origin
- path가 `/storage/v1/object/public/`로 시작
- username, password, fragment 없음
- 다운로드 redirect 거부
- 다운로드 결과가 실제 JPEG 또는 PNG
- 최대 10 MiB

다른 origin이나 임의 URL은 서버 측 요청 위조 경계를 넓히므로 거부한다.

## 5. Gemini 입력 정책

Gemini에는 아래 두 content block만 보낸다.

1. 앱이 고정한 비진단 관찰 지시문
2. 서버가 다운로드한 이미지의 base64와 확인된 MIME type

프롬프트는 다음을 금지한다.

- 건강 진단
- 질병명 또는 해충명 확정
- 물 부족·과습·광량·토양·뿌리 원인 추론
- 분갈이, 약제, 치료 또는 관리 처방
- 보이지 않는 정보 추론
- 자유 문장, confidence, 조치 제안 반환

`temperature: 0`, `thinking_level: minimal`, `thinking_summaries: none`,
`tool_choice: none`, `max_output_tokens: 160`으로 범위를 제한한다.

## 6. 구조화 출력 계약

모델이 생성할 수 있는 필드는 아래 세 개뿐이다.

```json
{
  "image_quality": "usable",
  "observation_state": "stable_appearance",
  "evidence_tags": ["stable_foliage"]
}
```

JSON Schema 정책:

- `additionalProperties: false`
- 세 필드 모두 필수
- `evidence_tags` 최대 4개
- G-1A allowlist enum만 허용
- `observation_id`, `observed_at`, 진단, 설명, 조치, confidence는 schema에 없음

허용 값은 G-1A 문서와 parser를 단일 기준으로 삼는다.

## 7. Edge Function 응답 계약

성공 응답:

```json
{
  "observation_id": "gateway-generated-uuid",
  "observed_at": "2026-06-24T05:06:07.000Z",
  "image_quality": "usable",
  "observation_state": "stable_appearance",
  "evidence_tags": ["stable_foliage"]
}
```

- `observation_id`는 gateway가 생성한다.
- `observed_at`은 gateway clock으로 기록한다.
- Gemini interaction id는 클라이언트에 반환하지 않는다.
- provider usage와 raw response도 반환하지 않는다.
- 모든 응답은 `Cache-Control: no-store`를 사용한다.

## 8. 방어적 정리 규칙

완료된 Interaction에 model output text가 있으면 JSON을 읽고 allowlist를 다시
검증한다.

아래 경우에는 정상·긍정 관찰로 부분 복구하지 않고 안전한 불확실 계약으로
강등한다.

- model output JSON 파싱 실패
- object가 아닌 출력
- 필수 필드 누락
- 알 수 없는 enum
- 문자열이 아닌 evidence tag
- 미승인 evidence tag
- tag 개수 초과

강등 값:

```json
{
  "image_quality": "unusable",
  "observation_state": "uncertain",
  "evidence_tags": ["image_unclear"]
}
```

그 다음 G-1A parser가 최종적으로 `condition_uncertain` 이벤트를 만든다.

## 9. 오류 정책

다음은 2xx 관찰 응답으로 위장하지 않고 오류로 반환한다.

- secret 또는 `SUPABASE_URL` 누락: 500
- 잘못된 요청 또는 URL: 400
- 이미지 10 MiB 초과: 413
- 이미지 다운로드 실패: 502
- Gemini 네트워크·timeout·비정상 status: 502
- Gemini non-2xx: 502
- Interaction outer JSON 손상: 502
- Interaction status가 `completed`가 아님: 502
- model output text 없음: 502

upstream 오류 body는 응답과 로그에 넣지 않는다.

## 10. 보안·개인정보 정책

- Gemini key 이름: `GEMINI_API_KEY`
- key는 Supabase Edge Function secret에만 저장
- Flutter source와 요청 body에 key를 넣지 않음
- query string 대신 `x-goog-api-key` header 사용
- Interactions 요청은 `store: false`
- 이미지 bytes, base64, 프롬프트, raw model output을 로그에 남기지 않음
- 성공 로그는 모델명, 계약 유효 여부, 입력·출력 token 수만 허용
- Gemini interaction id는 로그와 클라이언트 응답에서 제외

## 11. 비용·호출 통제

G-1B에서는 앱 runtime과 연결하지 않으므로 자동 호출과 실제 비용이 발생하지
않는다.

후속 runtime 연결 시에도 다음 정책을 유지한다.

- 명시적인 기본 상태 관찰 동작에서만 호출
- 일반 채팅에서 자동 호출하지 않음
- 한 사용자 동작당 최대 한 번
- 한 요청에 이미지 한 장
- timeout 후 자동 반복 호출 없음
- provider quota·비용 관찰 후 rollout

## 12. G-1B 완료 조건

- Edge Function handler가 dependency injection으로 테스트 가능
- 테스트가 실제 Supabase, Gemini, production secret을 사용하지 않음
- 안정 v1 Interactions endpoint 사용
- `store: false`와 JSON Schema가 요청에 포함됨
- G-1A 이외의 출력 필드가 클라이언트로 나가지 않음
- 미승인 model content가 안전한 uncertainty로 강등됨
- 이미지 origin·path·크기·형식 검증 완료
- upstream 오류 body와 key가 노출되지 않음
- 기존 Kindwise와 Flutter runtime은 변경되지 않음

## 13. 후속 단계

- G-1C: Flutter용 `GeminiDefaultObservationAdapter`와 Supabase Function invoke
  계약
- G-1D: 명시적 기본 상태 관찰 UX 및 runtime factory wiring
- G-1E: secret 등록 후 제한된 수동 실사진 검증과 비용·latency 관찰

G-1C에서도 네트워크 실패와 gateway 오류는 `condition_uncertain` 또는 명시적
재시도 UI로 처리하며, Kindwise 건강 분석 경계와 합치지 않는다.
