# Gemini 기본 상태 관찰 Flutter adapter (G-1C)

결정일: 2026-06-24

## 1. 목적

G-1C는 G-1A parser와 G-1B Supabase Edge Function gateway 사이에 놓일 Flutter
adapter 계약을 추가한다.

이 adapter는 `plant_analysis` 경계 안에서만 동작한다. Gemini를 식물 진단 공급자로
취급하지 않고, 기본 상태 관찰용 `default_observation` 분석 타입만 처리한다.

## 2. 이번 단계 범위

포함:

- `GeminiDefaultStateObservationAdapter`
- `InvokeGeminiDefaultObservationProxyCallback`
- proxy 응답을 G-1A parser로 넘기는 adapter 단위 테스트
- `PlantAnalysisService`를 통한 정규화 이벤트 흐름 확인
- `imageUrl`만 proxy callback으로 넘기는 최소 호출 계약 확인

제외:

- `main.dart` wiring
- `PlantConditionAnalysisService` 기본 adapter 교체
- Supabase client 직접 호출 구현
- 실제 Gemini 호출
- Edge Function 배포
- API key 또는 secret 설정
- DB schema 변경
- Kindwise runtime 연결

## 3. Adapter 계약

입력:

- `PlantAnalysisInput.analysisType == PlantAnalysisTypes.defaultObservation`
- 절대 HTTP 또는 HTTPS `imageUrl`

거부:

- `condition_check`
- `identification`
- `combined`
- 알 수 없는 분석 타입
- 빈 `imageUrl`
- 상대 경로, 로컬 파일 경로, `data:`, `file:`, `ftp:` URL

proxy callback에는 `imageUrl`만 전달한다. `plantId`, `speciesKey`,
`speciesDisplayName`, `userPrompt`, `metadata`, 로컬 `imagePath`는 Gemini gateway 호출
계약에 포함하지 않는다.

## 4. 응답 계약

adapter는 proxy 응답으로 다음 형태만 받는다.

- `Map<String, dynamic>`
- `Map`
- JSON `String`

그 외 값은 `FormatException`으로 거부한다.

응답 해석은 `GeminiDefaultStateObservationParser`에 위임한다. 따라서 다음 정책은 G-1A
parser와 동일하게 유지된다.

- 모델 자유 문장 무시
- 모델 confidence 무시
- 미승인 enum 또는 근거 태그는 `condition_uncertain`
- `rawPayload` 비저장
- `appearance_stable`은 건강 진단이 아닌 기본 외관 관찰

## 5. 완료 조건

- adapter 단위 테스트가 외부 네트워크 없이 통과한다.
- `PlantAnalysisService`를 통과해도 event type과 metadata가 보존된다.
- unsupported analysis type에서는 proxy가 호출되지 않는다.
- invalid URL에서는 proxy가 호출되지 않는다.
- 기존 Kindwise adapter, Supabase gateway, runtime wiring은 변경하지 않는다.
