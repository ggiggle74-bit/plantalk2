# Gemini 기본 상태 관찰 Supabase proxy invoker (G-1D)

결정일: 2026-06-26

## 1. 목적

G-1D는 G-1B Supabase Edge Function gateway와 G-1C Flutter adapter 사이의 실제 Flutter
Supabase Function 호출 경계를 추가한다.

이 단계는 `gemini-default-observe` Edge Function을 호출할 수 있는 작은 invoker만 제공한다.
앱 runtime에서 기본 상태 관찰을 켜거나, 기존 `condition_check` 흐름을 Gemini로 교체하지 않는다.

## 2. 이번 단계 범위

포함:

- `SupabaseGeminiDefaultObservationProxy`
- `gemini-default-observe` 함수명 기본값
- `imageUrl` 하나만 body에 넣어 Supabase Function을 호출하는 계약
- Supabase Function 응답의 `data`만 adapter로 반환하는 계약
- 네트워크 없는 단위 테스트를 위한 injectable function invoker
- `GeminiDefaultStateObservationAdapter`와의 조합 테스트

제외:

- `main.dart` wiring
- `PlantConditionAnalysisService` 기본 provider 교체
- 실제 Gemini 호출
- Edge Function 배포
- `GEMINI_API_KEY` secret 설정
- 상태 확인 버튼 또는 UI 변경
- Kindwise 실호출
- DB schema 변경

## 3. 호출 계약

기본 함수명:

```text
gemini-default-observe
```

Flutter에서 proxy가 보내는 body:

```json
{
  "imageUrl": "https://<project>.supabase.co/storage/v1/object/public/plant-photos/...jpg"
}
```

proxy는 다음 값을 Supabase Function으로 전달하지 않는다.

- `plantId`
- `speciesKey`
- `speciesDisplayName`
- `userPrompt`
- `metadata`
- 로컬 `imagePath`
- Gemini API key 또는 model name

## 4. 방어 규칙

proxy는 G-1C adapter 앞단에서도 같은 입력을 한 번 더 방어한다.

- `imageUrl`은 비어 있으면 안 된다.
- `imageUrl`은 절대 HTTP 또는 HTTPS URL이어야 한다.
- 상대 경로, 로컬 파일 경로, `data:`, `file:`, `ftp:` URL은 거부한다.
- function name은 비어 있으면 안 된다.
- function name은 소문자, 숫자, 하이픈으로만 구성된 Supabase Function slug여야 한다.

## 5. 응답 계약

`Supabase.instance.client.functions.invoke(...)`의 response object 전체를 노출하지 않는다.
proxy는 `response.data`만 반환한다.

해당 `data`는 G-1C adapter를 통해 G-1A parser로 전달된다. 따라서 Gemini 모델 자유 문장,
confidence, 진단·권장 조치 무시는 parser 정책으로 유지된다.

## 6. 완료 조건

- 단위 테스트가 실제 Supabase 또는 Gemini 네트워크 없이 통과한다.
- proxy body에 `imageUrl` 외 키가 들어가지 않는다.
- invalid URL 또는 invalid function name에서는 Supabase invoker가 호출되지 않는다.
- `GeminiDefaultStateObservationAdapter`와 조합했을 때 `default_observation` 이벤트로 정규화된다.
- 기존 runtime wiring, Kindwise adapter, Edge Function, DB schema는 변경하지 않는다.
