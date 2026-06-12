# Camera C plant_identification 외부 어댑터 매핑 설계

## 1. 문서 목적

이 문서는 향후 Plant.id 또는 Pl@ntNet 같은 외부 식물 식별 API를
`plant_identification` 경계에 연결할 때 사용할 입력/출력 매핑 원칙을 정리한다.

현재 단계에서는 실제 API 호출을 구현하지 않는다. 이 문서는 이후 외부 어댑터를
추가할 때 경계가 흐려지지 않도록 계약과 금지 사항을 명확히 하는 설계 문서다.

## 2. 경계 요약

- `plant_identification`은 첫 식물 등록 과정에서 사진으로 식물 정체성 후보를
  만드는 경계다.
- `plant_identification`은 식물을 생성하지 않는다.
- `plant_identification`은 식물 정체성을 자동 확정하지 않는다.
- 사용자의 후보 선택 또는 직접 입력은 이 경계 밖에서 처리한다.
- `plant_analysis`는 이미 등록된 식물의 상태/건강 확인 경계다.
- `plant_identification`과 `plant_analysis`는 섞지 않는다.

## 3. 후보 외부 API

향후 검토 가능한 외부 식물 식별 API 후보는 다음과 같다.

- Plant.id plant identification
- Pl@ntNet single-species identification

두 API 모두 이 문서 기준으로는 `PlantIdentificationAdapter` 구현체 뒤에 숨겨야
하며, 앱 런타임이나 등록 플로우가 특정 API 응답 구조에 직접 의존하면 안 된다.

## 4. PlantIdentificationInput 입력 매핑

외부 어댑터는 `PlantIdentificationInput` 값을 다음처럼 해석한다.

- `imageUrl`: 식별 대상 사진 위치. 외부 API가 접근 가능한 URL 또는 어댑터가
  전송 가능한 이미지 참조로 사용한다.
- `locale`: 후보 이름 또는 공통명 언어 선택에 사용할 수 있다.
- `requestedAt`: 요청 시각, 로깅/상관관계/결과 관찰 시각 기준으로 사용할 수 있다.
- `source`: 앱 내부에서 어떤 식별 진입점인지 구분하는 값으로 사용할 수 있다.
- `userId`: 필요할 경우 요청 상관관계 추적에만 사용한다.
- `plantId`: 포함하지 않는다. 첫 등록 식별은 식물 생성 전에 실행된다.

## 5. PlantIdentificationCandidate 출력 매핑

외부 API 후보 항목은 `PlantIdentificationCandidate`로 변환한다.

- `displayName`: UI에 표시할 대표 후보 이름.
- `scientificName`: 학명.
- `commonNames`: 공통명 목록. 가능하면 `locale`에 맞춘 이름을 우선 포함한다.
- `confidence`: 내부 기준 0.0부터 1.0 사이의 신뢰도.
- `candidateRank`: API 응답 순서 또는 어댑터가 계산한 후보 순위.
- `rawId`: 제공자가 주는 종/후보 식별자. 원본 응답 전체가 아니라 안전한 id만 저장한다.
- `source`: 후보를 만든 provider key.
- `metadata`: 안전하게 정규화된 메타데이터만 저장한다.

후보는 사용자가 검토할 선택지일 뿐이며, 후보 자체가 식물 정체성 확정 의미를
가지면 안 된다.

## 6. PlantIdentificationResult 결과 매핑

외부 API 전체 결과는 `PlantIdentificationResult`로 변환한다.

- `candidates`: 정규화된 후보 목록.
- `providerKey`: 결과를 만든 제공자 식별자. 예: `plant_id`, `plantnet`.
- `sourceResultId`: 제공자가 주는 요청/결과 id가 안전할 때만 저장한다.
- `observedAt`: 결과가 관찰된 시각. 일반적으로 요청 시각 또는 응답 완료 시각이다.
- `isMock`: 실제 외부 API 어댑터는 `false`, mock 어댑터는 `true`.
- `metadata`: 안전하게 정규화된 메타데이터만 저장한다.

## 7. Confidence 정책

- 내부 `confidence` 값은 0.0부터 1.0 사이로 정규화한다.
- 제공자가 0부터 100 사이 값을 반환하면 100으로 나누어 0.0부터 1.0 사이로 변환한다.
- 제공자가 신뢰도를 주지 않으면 `confidence`는 비워두고 `candidateRank`를 기준으로
  후보 순서를 유지한다.
- 신뢰도는 후보 정렬에 사용할 수 있지만, 식물 정체성 자동 확정에 사용하지 않는다.

## 8. Metadata 정책

`metadata`에는 원본 제공자/API payload를 저장하지 않는다.

저장하면 안 되는 값:

- API key
- 요청/응답 header
- 이미지 bytes
- 요청 body
- 전체 raw response
- 사용자나 기기 식별에 불필요한 민감 정보

나중에 메타데이터가 필요하면 whitelist 방식으로 안전한 키만 허용한다.

권장 safe key:

- `providerModelVersion`
- `apiCandidateIndex`
- `matchedBy`
- `language`

## 9. 실패/빈 결과 정책

- 후보가 비어 있어도 식물을 생성하면 안 된다.
- 후보가 비어 있으면 UI는 사용자의 직접 입력을 허용해야 한다.
- 네트워크/API 오류가 첫 등록 플로우를 영구적으로 막으면 안 된다.
- 외부 식별 실패 시에도 사용자는 수동으로 식물 종류/이름을 입력할 수 있어야 한다.
- 실패 처리는 어댑터 또는 서비스 호출부에서 최소한으로 보고하되, 등록 경계 밖의
  식물 생성 정책을 바꾸면 안 된다.

## 10. 명시적 비목표

현재 단계에서 하지 않는 일:

- HTTP client 추가
- API key 추가
- 실제 API 호출 구현
- Supabase schema 변경
- 런타임 연결
- `main.dart` 변경
- `PlantService` 변경
- 첫 등록 플로우 변경
- 기존 식물 상태 확인 플로우 변경

## 11. future implementation checklist

향후 외부 API 어댑터 구현 전 확인할 항목:

- provider 선택
- 외부 API 전용 adapter 생성
- provider 응답을 `PlantIdentificationCandidate` 목록으로 매핑
- confidence를 0.0부터 1.0 사이로 정규화
- metadata whitelist 적용
- 사용자 후보 선택/직접 입력은 boundary 밖에 유지
- 런타임 연결 전 테스트 또는 수동 확인 추가
- `plant_identification`과 `plant_analysis` 경계가 섞이지 않았는지 재확인
