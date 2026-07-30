# CR-2X: 심층 건강분석 런타임과 UI

## 사용자 흐름

저장된 식물 카드에는 일반 상태 확인과 별도로 심층 진단 버튼이 보인다.

1. 사용자가 사진을 고른다.
2. 앱이 서버에 무료횟수 예약을 요청한다.
3. 허용되면 상태 사진을 저장한다.
4. Edge Function은 인증 토큰과 예약 ID를 확인하고, 서버에서 그 예약을 한 번만 claim한다.
5. claim이 성공한 요청만 Kindwise 건강 분석으로 진행한다.
6. 결과 메모리 저장까지 완료되면 사용을 확정한다.
7. 실패하면 예약을 반환한다.

기본 정책은 사용자별 무료 1회이며, 정상 완료 시점부터 30일이 지나면 자동으로 다시 1회 사용할 수 있다. 소진 중에는 앱이 서버가 계산한 다음 사용 가능 시각을 안내한다.

## 리셋 기간 변경

앱 코드나 클라이언트는 정책 테이블을 바꿀 수 없다. 운영자는 Supabase SQL Editor에서 아래처럼 전역 리셋 기간만 변경한다. 앱 업데이트나 사용자별 수동 초기화는 필요 없다.

```sql
update public.deep_health_usage_policy
set reset_interval_days = 14,
    updated_at = now()
where policy_key = 'default';
```

허용 범위는 1~365일이며 기본값은 30일이다. 기간 변경은 새 예약 판단부터 적용된다. 이미 정상 완료된 건도 바뀐 기간 기준으로 다시 계산된다.

## 서버 보호

- claim은 auth.uid() 기준으로 본인 예약만 다룬다.
- claimed 상태는 무료 한도를 계속 점유한다.
- 같은 예약의 두 번째 Edge Function 호출은 Provider 호출 전에 거절된다.
- reserved와 claimed 예약은 만료되면 다음 예약에서 expired로 회수된다.
- committed 상태만 리셋 기간 안에서 무료 한도를 점유한다.
- commit과 release는 claimed 상태도 처리한다.
- Edge Function은 사용자의 JWT로 RPC를 호출한다. 서비스 역할 키를 앱이나 Function 응답에 노출하지 않는다.

## 유지한 경계

- 일반 상태 확인은 Gemini의 default_observation 흐름을 계속 사용한다.
- 심층 분석만 예약 ID를 가진 Reserved Kindwise adapter를 사용한다.
- 심층 결과는 기존 condition_check와 다른 deep_health_assessment 메모리로 저장한다.
- 대화 엔진은 Kindwise와 quota RPC를 직접 호출하지 않는다.

## 배포 전 조건

이 PR을 병합해도 실제 기능을 사용하려면 다음 순서가 필요하다.

1. 20260730070000, 20260730080000, 20260730090000 Supabase migration 적용
2. plant-health-assess Edge Function 배포
3. SUPABASE_ANON_KEY와 KINDWISE_PLANT_HEALTH_API_KEY 확인
4. 실제 기기에서 무료 1회, 중복 탭, 실패 반환, 리셋 시점, 소진 안내를 확인

마이그레이션과 배포는 자동 실행하지 않는다.
