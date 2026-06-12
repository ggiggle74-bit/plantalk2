# Camera C plant_identification 외부 API integration gate

## 1. 목적

이 문서는 실제 외부 `plant_identification` adapter 구현 전에 반드시 통과해야 하는
gate를 정의한다.

목적은 다음 문제를 사전에 막는 것이다.

- 너무 이른 API wiring
- API key 노출
- `plant_identification`과 `plant_analysis` 경계 혼합
- 첫 등록 플로우와 외부 API 응답의 강한 결합
- API 결과만으로 식물 생성 또는 정체성 자동 확정

현재 phase에서는 실제 API 구현을 하지 않는다.

## 2. 현재 완료된 기반

Camera C에서 완료된 기반은 다음과 같다.

- C-3: `plant_identification` skeleton 생성 완료
- C-5: skeleton hardening 완료
- C-6: API-ready contract review 완료
- C-7: adapter mapping 문서 완료
- C-8: provider/metadata comment hardening 완료
- C-9: provider comparison 문서 완료

이 문서는 위 기반 다음 단계로, 실제 외부 adapter 구현 전 승인 조건을 명확히 한다.

## 3. 모든 gate item 통과 전 integration 금지

아래 항목이 모두 확인되기 전에는 실제 외부 API adapter 구현, API key 추가, 런타임
연결을 진행하지 않는다.

### Provider / 계약 확인

- [ ] provider selected
- [ ] pricing/quota verified
- [ ] commercial/terms-of-use verified
- [ ] image input method verified
- [ ] response candidate shape verified
- [ ] confidence format verified
- [ ] common/scientific name fields verified
- [ ] Korean/common-name quality manually checked

### 데이터 매핑 / 보안 확인

- [ ] metadata whitelist decided
- [ ] API key storage plan decided
- [ ] no raw payload persistence plan confirmed
- [ ] no API key, headers, image bytes, request body, full raw response stored in metadata

### 사용자 플로우 fallback 확인

- [ ] manual entry fallback confirmed
- [ ] empty candidates behavior confirmed
- [ ] API/network failure fallback confirmed
- [ ] user confirmation remains outside boundary
- [ ] no automatic plant creation by API result

### 앱 경계 / 부작용 확인

- [ ] no representative image side effect
- [ ] no `plant_analysis` coupling
- [ ] no `PlantService` dependency inside `plant_identification`
- [ ] no Supabase schema change unless separately approved
- [ ] runtime connection plan separately reviewed

## 4. 구현 전 필요한 작은 manual test set

테스트 코드는 아직 추가하지 않는다. provider 검증 phase에서 같은 사진 세트로 수동
확인한다.

권장 test set:

- indoor plant clear photo
- indoor plant blurry photo
- leaf-only photo
- non-plant / bad photo
- Korean common houseplant
- unknown/ambiguous plant

각 사진에서 확인할 항목:

- candidate count
- candidate order
- displayName quality
- scientificName quality
- confidence range
- manual fallback usability

수동 확인 결과는 provider 선택 또는 adapter 구현 승인 근거로 남겨야 한다.

## 5. Gate 승인 후 허용되는 future implementation shape

Gate가 승인된 뒤에도 구현 범위는 작게 유지한다.

- `lib/plant_identification/adapters/` 아래에 외부 adapter 하나를 생성한다.
- 외부 adapter는 `PlantIdentificationAdapter`를 구현한다.
- 외부 adapter는 provider response를 `PlantIdentificationResult`로 매핑한다.
- `PlantIdentificationCandidate`에는 후보 옵션만 담는다.
- `PlantIdentificationNormalizer`는 cleanup/order 책임을 유지한다.
- `PlantIdentificationService`는 adapter + normalizer orchestration만 유지한다.
- 사용자 후보 선택/직접 입력은 boundary 밖에 둔다.
- 런타임 연결은 별도 phase에서 리뷰한다.

## 6. 이번 phase의 명시적 비목표

이번 phase에서는 하지 않는다.

- HTTP client 추가
- API key 추가
- 실제 API 호출 구현
- `main.dart` 변경
- `PlantService` 변경
- Supabase schema 변경
- 첫 등록 플로우 변경
- condition-check flow 변경
- `plant_analysis` 변경

## 7. 이 문서 이후 권장 next decision

이 문서 이후 선택지는 다음 중 하나다.

- Camera C boundary preparation을 여기서 중단한다.
- 별도 provider verification phase로 이동한다.
- Mobile UI Fix-1로 전환해 registration photo preview size 문제를 다룬다.
