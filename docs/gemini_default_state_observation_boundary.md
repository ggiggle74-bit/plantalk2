# Gemini 기본 상태 관찰 경계 (G-1A)

결정일: 2026-06-24

참고한 공식 문서:

- https://ai.google.dev/gemini-api/docs/structured-output
- https://ai.google.dev/gemini-api/docs/image-understanding
- https://ai.google.dev/api/generate-content

## 1. 목적

G-1A는 Gemini 실호출 전에 **기본 상태 관찰 결과 계약과 앱 내부 안전 매핑**을
확정한다.

이 경계의 역할은 사진에서 보이는 제한된 시각 신호를 기록하는 것이다. 식물 건강을
진단하거나 물주기, 병해충, 약제 사용 같은 조치를 결정하지 않는다.

Kindwise `condition_check` 경계는 그대로 유지한다. Gemini 기본 상태 관찰은 별도의
`default_observation` 분석 타입을 사용하며 Kindwise 실호출이나 런타임 연결을 요구하지
않는다.

## 2. 이번 단계 범위

포함:

- `PlantAnalysisTypes.defaultObservation`
- 비진단 상태인 `PlantAnalysisEventTypes.appearanceStable`
- 구조화된 Gemini 관찰 결과를 읽는 순수 parser
- 허용 목록 기반 상태·근거 교차 검증
- 앱이 작성한 한국어 문구만 반환하는 정책
- 불명확하거나 우려 신호가 있는 결과의 `condition_uncertain` 강등
- 네트워크 없는 단위 테스트

제외:

- Gemini API 호출
- API key 또는 Supabase secret 추가
- 모델명 고정
- Supabase Edge Function 추가 또는 변경
- `main.dart` 런타임 wiring
- DB schema 또는 `PlantService` 변경
- Kindwise 실호출
- 사진 기반 질병명, 해충명, 물주기 처방 생성

## 3. 입력 경계

앱 내부 입력은 `PlantAnalysisInput`을 사용한다.

필수 정책:

- `analysisType == default_observation`
- `plantId`는 앱이 관리한다.
- 이미지 전달과 Gemini 호출은 후속 서버 경계에서만 구현한다.
- Flutter가 Gemini API key를 보유하거나 Gemini를 직접 호출하지 않는다.

`condition_check` 입력으로 이 parser를 호출하면 `UnsupportedError`를 발생시킨다. 이
검사는 Gemini 관찰 결과가 Kindwise 건강 진단 경계로 섞이는 것을 막는다.

## 4. 구조화 출력 계약

후속 Gemini gateway는 JSON schema를 사용해 아래 필드만 parser에 전달해야 한다.

```json
{
  "observation_id": "server-generated-id",
  "observed_at": "2026-06-24T00:00:00Z",
  "image_quality": "usable",
  "observation_state": "stable_appearance",
  "evidence_tags": ["stable_foliage"]
}
```

허용 `image_quality`:

- `usable`
- `limited`
- `unusable`

허용 `observation_state`:

- `stable_appearance`
- `growth_positive`
- `new_leaf_observed`
- `flowering_observed`
- `visible_concern`
- `uncertain`

허용 근거 태그:

- 긍정·중립: `stable_foliage`, `new_growth`, `new_leaf`, `flowering`
- 우려·품질: `visible_discoloration`, `visible_wilting`, `visible_damage`,
  `leaf_drop`, `image_unclear`

`observation_id`와 `observed_at`은 모델이 자유 생성하는 값이 아니라 후속 gateway가
주입하는 provenance 값으로 취급한다.

## 5. 교차 검증 규칙

1. `image_quality`가 `usable`이 아니면 `condition_uncertain`이다.
2. 우려·품질 태그가 하나라도 있으면 모델이 긍정 상태를 주장해도
   `condition_uncertain`이다.
3. 긍정·중립 상태는 일치하는 근거 태그가 있어야 한다.
4. 상태 누락, 알 수 없는 enum, 근거 누락 또는 상충은 `condition_uncertain`이다.
5. parser는 결과마다 이벤트 하나만 만든다.
6. 모델이 반환한 자유 문장, 진단, 권장 조치, 자기 보고 confidence는 신뢰하지 않는다.
7. `rawPayload`에는 원본 Gemini 응답을 저장하지 않는다.

## 6. PlantAnalysis 이벤트 매핑

| 관찰 상태 | 필수 근거 | PlantAnalysis 이벤트 | 정책 |
| --- | --- | --- | --- |
| `stable_appearance` | `stable_foliage` | `appearance_stable` | 겉보기 관찰일 뿐 건강 판정이 아님 |
| `growth_positive` | `new_growth` | `growth_positive` | 긍정 성장 신호만 기록 |
| `new_leaf_observed` | `new_leaf` | `new_leaf_observed` | 새 잎 관찰만 기록 |
| `flowering_observed` | `flowering` | `flowering_observed` | 개화 관찰만 기록 |
| `visible_concern` | 선택 | `condition_uncertain` | 별도 건강 확인 필요 |
| `uncertain` 또는 계약 불일치 | 해당 없음 | `condition_uncertain` | 안전한 기본값 |

`appearance_stable`은 기존 `health_ok`와 구분한다. downstream에서는 `normal` 상태로
표현할 수 있지만, 문구는 반드시 “건강 진단 결과가 아니다”라는 제한을 유지한다.

## 7. 문구 정책

모델이 생성한 `summary_ko`, `diagnosis`, `recommended_action` 같은 필드는 무시한다.
사용자에게 노출할 첫 문장은 앱 코드의 고정된 완곡 표현만 사용한다.

예시:

- 안정적 외관: `사진에서 겉으로 보이는 상태가 비교적 안정적으로 보여요. 건강 진단 결과는 아니에요.`
- 우려 신호: `사진에서 확인이 필요한 변화가 보일 수 있어요. 정확한 판단은 별도 건강 확인이 필요해요.`
- 불확실: `사진만으로는 기본 상태를 안정적으로 관찰하기 어려워요.`

Gemini 결과만으로 질병명, 해충명, 물 부족, 과습, 광량 부족, 분갈이 필요 여부 또는
약제 사용을 말하지 않는다.

## 8. G-1A 완료 조건

- 구조화 결과 parser가 외부 네트워크 없이 동작한다.
- `default_observation` 외 분석 타입은 거부한다.
- 정상 외관과 건강 진단이 이벤트 수준에서 구분된다.
- 모델 자유 문장과 confidence가 결과에 반영되지 않는다.
- 우려 신호와 불완전한 결과는 모두 `condition_uncertain`으로 강등된다.
- 기존 Kindwise adapter, Edge Function, runtime wiring은 변경하지 않는다.

후속 단계에서만 서버 측 Gemini 호출, JSON schema enforcement, 모델 선택, 비용 제한,
timeout, observability와 수동 사진 검증을 추가한다.
