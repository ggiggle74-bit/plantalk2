# CR-2U: 심층 건강분석 슬롯 계약

## 목적

일반 상태확인과 유료·제한형 심층 건강분석을 별도 실행 경로로 분리한다. 이 단계에서는 UI, 실결제, Kindwise 런타임 호출을 연결하지 않고 실행 순서와 차단 경계만 확정한다.

## 실행 순서

1. 서버 권한 확인과 무료횟수 예약
2. 승인된 경우에만 사진 저장
3. 심층 건강분석 실행
4. `deep_health_assessment` 메모리 생성
5. 메모리 저장 완료 후 결과 반환

권한 확인이 거절되거나 실패하면 사진 저장, 분석 provider, 메모리 저장을 호출하지 않는다.

## 권한 경계

`DeepHealthAssessmentGateService.authorizeAndReserve`는 단순 화면용 조회가 아니라 서버에서 사용자 권한 또는 무료횟수를 확인하고 사용량을 예약하는 계약이다. 기존 `LocalEntitlementGateService`는 UI와 테스트용 정책이므로 실제 Kindwise 호출 앞의 보안 경계로 사용할 수 없다.

게이트 결과는 반드시 `PaidFeature.deepHealthAssessment`에 관한 것이어야 하며, 허용 여부와 결제 필요 여부가 서로 모순되면 흐름을 중단한다.

## 메모리 분리

- 일반 상태확인: `condition_check`
- 심층 건강분석: `deep_health_assessment`

심층 결과는 일반 상태 기억 조회에 섞이지 않는다. 대화 엔진은 계속 정규화된 일반 상태 기억만 사용하며 Kindwise를 직접 호출하지 않는다.

## 이번 CR에서 제외

- `main.dart`와 PlantCard 버튼 변경
- 결제 안내 다이얼로그와 실제 구매
- 서버 quota 테이블·RPC·Edge Function 구현
- Kindwise 실제 호출 활성화
- Supabase 스키마 변경
