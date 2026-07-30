# CR-2R: 종별 캐릭터 말투 컨텍스트

## 목적

저장된 식물 종을 일상 대화의 작은 말투 차이로 반영하되, 대화 처리 경로와 API 호출 수를 늘리지 않는다.

## 결정 경계

- 판단 입력은 Supabase에서 읽은 정규화 `species_key`뿐이다.
- `species_display_name`과 사용자가 입력한 캐릭터 이름은 종 성격 판단에 사용하지 않는다.
- 알 수 없거나 지원하지 않는 키는 원문을 그대로 반환한다.
- 적용 위치는 `LocalCasualConversationEngine`이 이미 사용하는 `PlantCharacterToneComposer` 한 곳이다.
- DB 대사, 상태 기억, 카메라 분석 결과, Gemini 응답에는 종 말투를 다시 합성하지 않는다.

## 우선순위와 빈도

1. 현재 기분
2. 높은 친밀도
3. 종별 캐릭터 말투
4. 변경 없는 기본 대사

종별 말투는 안정 해시 기준 5회 중 약 1회만 적용한다. 매 응답에 같은 접두어가 붙는 현상을 막고, 캐릭터가 과장되지 않게 한다.

## 종 그룹

| 키 | 낮은 빈도의 표현 방향 |
| --- | --- |
| `monstera`, `monstera_deliciosa` | 활기차고 다정함 |
| `stucky`, `sansevieria` | 차분하고 절제됨 |
| `pothos`, `philodendron`, `ivy` | 호기심과 연결감 |
| `rubber_tree`, `dracaena_fragrans`, `pachira`, `schefflera`, `areca_palm` | 든든하고 느긋함 |
| `alocasia`, `calathea`, `peperomia` | 세심하고 감각적임 |
| `succulent`, `cactus` | 짧고 솔직함 |

## 비목표

- 새로운 라우터나 대화 처리 슬롯 추가
- 종 선택·식물 등록·카메라 흐름 변경
- 종별 대사 테이블 신설
- Gemini 프롬프트 또는 호출 조건 변경
