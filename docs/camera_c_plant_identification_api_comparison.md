# Camera C plant_identification API provider 비교

## 1. 목적

이 문서는 향후 첫 식물 등록용 식물 식별 API provider를 선택하기 위한 비교 문서다.

이 문서는 실제 API 구현을 승인하지 않는다. 현재 단계에서는 provider 후보의 장단점,
매핑 난이도, 비용/쿼터 위험, 보안 고려사항을 정리하는 데 목적이 있다.

참고한 공개 문서:

- Plant.id by kindwise: https://www.kindwise.com/plant-id
- Kindwise pricing: https://www.kindwise.com/pricing
- Pl@ntNet API pricing: https://my.plantnet.org/pricing
- Pl@ntNet single-species identification: https://my.plantnet.org/doc/api/identify
- Pl@ntNet quota management: https://my.plantnet.org/doc/api/quota

## 2. 경계 요약

- `plant_identification`은 첫 등록 과정에서 사진으로 식물 정체성 후보를 만드는
  boundary다.
- `plant_identification`은 식물을 생성하지 않는다.
- `plant_identification`은 식물 정체성을 자동 확정하지 않는다.
- 사용자 후보 선택 또는 직접 입력은 boundary 밖에서 처리한다.
- `plant_analysis`는 이미 등록된 식물의 상태/건강 확인 boundary다.
- `plant_identification`과 `plant_analysis`는 섞지 않는다.

## 3. 비교 기준

provider 선택 전에 다음 기준을 비교한다.

- 식별 정확도 기대치
- 후보 목록 품질
- 한국어/공통명 처리
- 학명 제공 여부
- confidence score 제공 여부
- 응답 매핑 난이도
- free tier / quota 위험
- pricing 위험
- API key/security 처리
- 이미지 입력 요구사항
- raw payload leakage 위험
- MVP 적합성
- 장기 확장성

## 4. Plant.id 분석

### 예상 강점

- 식물 식별 전용 상용 API이며, 앱/서비스 통합을 전제로 제공된다.
- 공개 설명 기준으로 common names, synonyms, taxonomy 같은 식물 상세 데이터가
  제공된다.
- houseplants, garden plants, wild plants 등 앱 사용자 사진에서 나올 가능성이 큰
  범위를 폭넓게 다루는 방향이다.
- Plantalk MVP가 실내 식물/반려 식물 등록 경험에 집중한다면 후보 품질 검증 가치가
  높다.
- pricing 문서 기준으로 등록 후 100 free credits가 있어 초기 API shape 확인에는
  적합할 수 있다.

### 예상 위험

- 무료 사용량이 작다. MVP 실험 이후에는 요청당 credit 비용과 credit 유효기간을
  확인해야 한다.
- 정확도/커버리지 설명은 vendor claim이므로 Plantalk 실제 사진, 특히 한국 사용자
  환경의 실내 식물 사진으로 별도 검증해야 한다.
- 다국어 common name coverage는 언어별 차이가 있을 수 있다. 한국어 이름 품질은
  실제 응답으로 확인해야 한다.
- Postman 문서 기반 API shape가 변경될 수 있으므로 adapter 구현 전 최신 문서를
  다시 확인해야 한다.
- API key, 요청 body, 이미지 데이터, 전체 raw response를 앱 상태나 metadata에
  저장하지 않도록 강한 매핑 경계가 필요하다.

### PlantIdentificationCandidate 매핑 메모

- `displayName`: provider가 주는 preferred common name이 있으면 우선 사용하고,
  없으면 scientific name으로 fallback한다.
- `scientificName`: taxonomy/species 필드에서 매핑한다.
- `commonNames`: provider common names 또는 synonyms 중 UI에 안전한 이름만 담는다.
- `confidence`: provider가 0-100 형식이면 0.0-1.0으로 변환한다.
- `candidateRank`: 응답 순서를 1부터 시작하는 rank로 매핑한다.
- `rawId`: 안전한 provider plant/species id만 저장한다.
- `source`: `plant_id` 같은 provider key를 사용한다.

### metadata whitelist 고려

허용 후보:

- `providerModelVersion`
- `apiCandidateIndex`
- `matchedBy`
- `language`

금지:

- API key
- 요청/응답 headers
- image bytes
- request body
- full raw response
- 사용자 식별에 불필요한 provider-side trace

### MVP 적합성

Plant.id는 MVP 후보로 검토할 가치가 높다. 다만 100 free credits 이후 비용 위험이
있으므로, 실제 연결 전에는 작은 수동 테스트 세트로 후보 품질과 한국어/공통명 품질을
확인해야 한다.

## 5. Pl@ntNet 분석

### 예상 강점

- 공개 문서 기준으로 single-species identification은 probable species top-list를
  confidence score 내림차순으로 반환한다.
- confidence score가 0부터 1 사이로 제공되어 현재 내부 `confidence` 계약과 잘 맞다.
- 응답 예시에 `species.scientificName`, `species.commonNames`, `gbif.id`,
  `powo.id`, `version`, `remainingIdentificationRequests`가 포함되어 후보/metadata
  매핑이 비교적 명확하다.
- free plan 기준 500 identifications/day가 제공되어 MVP 검증 쿼터가 비교적 넉넉하다.
- 비영리/교육/과학 목적에 대한 별도 조건도 있어 장기 정책 확인 여지가 있다.

### 예상 위험

- Pl@ntNet은 시민과학/생물다양성 기반 성격이 강해, 실내 반려식물 UX에 최적인지는
  실제 테스트가 필요하다.
- common name은 `lang` 파라미터와 language coverage에 따라 품질이 달라질 수 있다.
  한국어 지원 여부와 실제 한국어 common name 품질은 구현 전 확인해야 한다.
- free plan의 로고/표기 요구사항, terms of use, 상업적 사용 조건을 반드시 확인해야
  한다.
- 이미지 입력은 JPG/PNG binary file 기반이며, 최대 5장 및 전체 POST size 제한이
  있으므로 현재 `imageUrl` 계약과 실제 adapter 전송 방식 사이에 변환 설계가 필요하다.
- quota 관련 값과 headers를 metadata에 그대로 저장하면 raw/provider payload leakage
  위험이 있다.

### PlantIdentificationCandidate 매핑 메모

- `displayName`: `species.commonNames` 중 locale에 맞는 첫 항목을 우선 사용하고,
  없으면 `species.scientificName` 또는 `bestMatch`를 사용한다.
- `scientificName`: `species.scientificName`을 사용한다.
- `commonNames`: `species.commonNames`를 안전한 문자열 목록으로 매핑한다.
- `confidence`: `results[].score`를 그대로 사용한다.
- `candidateRank`: `results` 배열 순서를 1부터 시작하는 rank로 매핑한다.
- `rawId`: `gbif.id` 또는 `powo.id` 중 안정적인 값을 선택한다.
- `source`: `plantnet` provider key를 사용한다.

### metadata whitelist 고려

허용 후보:

- `providerModelVersion`: 응답의 `version`
- `apiCandidateIndex`: `results` 배열 index
- `language`: 응답/요청 language
- `matchedBy`: `bestMatch` 또는 project/referential 정보 중 안전한 요약값

금지:

- API key
- request query 전체
- quota headers 전체
- image file hash/raw image id
- full raw response
- related images 원본 목록

### MVP 적합성

Pl@ntNet은 MVP 테스트 첫 후보로 보수적으로 적합하다. 이유는 free quota가 명확하고,
confidence가 0-1 범위이며, 후보 목록/학명/공통명 응답 구조가 현재
`PlantIdentificationCandidate` 계약에 가깝기 때문이다.

다만 실내 식물 사진에서 Plant.id보다 후보 품질이 낮을 가능성은 검증해야 한다.

## 6. 초기 추천

초기 MVP provider 테스트는 Pl@ntNet을 먼저 검토하는 것을 추천한다.

보수적 이유:

- 공개 문서 기준 free plan 500 identifications/day로 초기 검증 부담이 낮다.
- confidence score가 내부 계약과 같은 0.0-1.0 범위다.
- top-list 후보 구조가 `PlantIdentificationCandidate` 목록 매핑에 직접적이다.
- 학명, common names, provider version, quota 관련 정보가 문서상 명확하다.

다만 최종 선택 전 다음은 반드시 확인해야 한다.

- 한국어 또는 한국 사용자에게 익숙한 common name 품질
- 실내 식물/반려 식물 사진에서의 후보 정확도
- free/pro plan의 표시 의무와 상업적 사용 조건
- 현재 `imageUrl` 입력 계약과 실제 binary upload 요구사항의 adapter 설계

Plant.id는 실내 식물/상용 앱 품질 면에서 강점이 있을 수 있으므로, Pl@ntNet 테스트
결과가 부족하면 두 번째 후보로 같은 사진 세트 비교를 진행한다.

## 7. 구현 비목표

현재 단계에서 하지 않는다.

- HTTP client 추가
- API key 추가
- 실제 API 호출 구현
- Supabase schema 변경
- 런타임 연결
- `main.dart` 변경
- `PlantService` 변경
- 첫 등록 플로우 변경

## 8. future decision checklist

provider 선택 전 확인한다.

- pricing/quota 확인
- image upload method 확인
- candidate response shape 확인
- confidence format 확인
- common/scientific name fields 확인
- provider terms 확인
- metadata whitelist 결정
- boundary review 후에만 adapter 추가
