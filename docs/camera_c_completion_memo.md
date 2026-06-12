# Camera C 완료 메모

## 1. Camera C 목적

Camera C의 목적은 첫 식물 등록용 식물 식별과 기존 식물 상태 분석을 명확히 분리하는
것이다.

- 첫 등록 사진 식별은 `plant_identification` 경계에서 후보 식물 정체성 옵션만 만든다.
- 기존 식물 상태/건강 확인은 `plant_analysis` 경계에서 처리한다.
- 향후 외부 식물 식별 API를 붙일 수 있도록 계약과 문서를 준비한다.
- 이번 Camera C에서는 실제 외부 API 구현을 하지 않는다.

## 2. 완료된 phase

- C-0: API candidate decision
- C-1: `plant_analysis` adapter contract review
- C-2: `plant_identification` boundary document
- C-3: `plant_identification` skeleton
- C-4: skeleton structure review
- C-5: skeleton hardening
- C-6: API-ready contract review
- C-7: external adapter mapping document
- C-8: `providerKey` / metadata policy comments
- C-9: Plant.id / Pl@ntNet comparison document
- C-10: integration gate document

## 3. 중요 commit

- `cc7f65b` Add plant identification boundary skeleton
- `29bb943` Harden plant identification skeleton
- `ae76ecb` Restore condition check chat navigation
- `73b1d6e` Clarify plant identification provider metadata policy
- `c941c99` Document plant identification API comparison
- `376e98c` Document plant identification integration gate

## 4. 최종 architecture 상태

- `plant_identification`은 첫 등록용 식물 정체성 후보 boundary다.
- `plant_analysis`는 기존 식물 상태/건강 확인 boundary다.
- 두 boundary는 분리되어 있다.
- `plant_identification`은 아직 runtime에 연결되어 있지 않다.
- `plant_identification`은 식물을 생성하지 않는다.
- `plant_identification`은 식물 정체성을 자동 확정하지 않는다.
- 사용자 후보 선택 또는 직접 입력은 boundary 밖에 남아 있다.
- 기존 condition-check 사진은 대표 이미지와 분리되어 있다.
- condition-check 사진은 `plants.photo_url` 또는 대표 이미지를 교체하지 않는다.

## 5. 명시적으로 하지 않은 일

- 실제 API call 구현 없음
- HTTP client 추가 없음
- API key 추가 없음
- Supabase schema 변경 없음
- runtime connection 없음
- 첫 등록 flow integration 없음
- `PlantService` coupling 없음
- `plant_analysis`와 `plant_identification` 혼합 없음

## 6. 이 기간 함께 완료된 mobile fix

- 기존 식물 condition-check flow에서 상태 결과 확인 후 같은 식물 chat으로 돌아가도록
  navigation을 복구했다.
- mobile latest build/web serving을 검증했다.
- registration photo preview size 문제는 사용자가 별도로 해결했다.

## 7. 남은 future option

- Pl@ntNet / Plant.id provider verification phase 진행
- integration gate 통과 후에만 real external adapter implementation 진행
- 첫 등록 UI에서 후보 목록 선택/직접 입력 integration 진행, 현재는 deferred
- 필요한 경우 mobile UI polish 진행
- Camera C는 다음 feature block으로 넘어가기 전에 closed로 간주할 수 있다.
