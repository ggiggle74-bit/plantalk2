# CR-2W: 심층 건강분석 서버 무료횟수

## 목적

무료 심층 건강분석 1회를 클라이언트 상태가 아니라 인증 사용자별 Supabase 서버 상태로 관리한다. 중복 탭, 여러 기기, 분석 실패가 있어도 무료횟수 판정과 반환을 원자적으로 처리할 기반을 만든다.

## 서버 상태

- deep_health_usage_accounts: 사용자별 무료 한도. 기본값은 1회다.
- deep_health_usage_reservations: reserved, committed, released, expired 생명주기를 기록한다.
- 예약은 15분 뒤 만료되며 다음 예약 시 서버가 회수한다.
- 확정된 예약과 아직 유효한 예약만 한도를 점유한다.
- 두 테이블은 RLS를 켜고 클라이언트 직접 권한을 제거한다.

## RPC 계약

- reserve_deep_health_assessment_usage()
  - auth.uid()로 사용자를 결정한다.
  - 사용자 계정 행을 잠근 뒤 한도 확인과 예약 생성을 한 트랜잭션에서 수행한다.
  - 허용 시 예약 ID를 반환하고, 소진 시 결제 필요 결정을 반환한다.
- commit_deep_health_assessment_usage(uuid)
  - 본인 예약만 확정한다.
  - 이미 확정된 요청은 같은 상태를 반환한다.
  - 만료·반환된 예약은 확정되지 않는다.
- release_deep_health_assessment_usage(uuid)
  - 본인의 유효한 예약만 반환한다.
  - 이미 반환·만료·확정된 요청은 현재 상태를 그대로 반환한다.

세 RPC는 SECURITY DEFINER와 제한된 search_path를 사용하며 authenticated 역할에만 실행 권한을 준다.

## Flutter 경계

SupabaseDeepHealthAssessmentGateService는 서버 응답을 기존 DeepHealthAssessmentGateService 계약으로 변환한다. 클라이언트가 전달한 currentUsage는 권한 판단에 사용하지 않는다. 응답 필드가 없거나 모순되면 허용하지 않고 오류로 종료한다.

## 이번 변경에서 활성화하지 않는 것

- main.dart 런타임 조립
- 심층 건강분석 UI
- Kindwise Edge Function 호출
- 결제 및 구매 복원
- 실제 Supabase 마이그레이션 적용

다음 CR에서 Edge Function이 예약을 검증하도록 연결한 뒤 UI에 노출한다.
