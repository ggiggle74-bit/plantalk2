import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/'
    '20260730070000_deep_health_usage_quota.sql',
  ).readAsStringSync();

  test('quota tables are private RLS-protected server state', () {
    expect(migration, contains('deep_health_usage_accounts'));
    expect(migration, contains('deep_health_usage_reservations'));
    expect(
      migration,
      contains(
        'alter table public.deep_health_usage_accounts '
        'enable row level security',
      ),
    );
    expect(
      migration,
      contains(
        'alter table public.deep_health_usage_reservations '
        'enable row level security',
      ),
    );
    expect(
      migration,
      contains('revoke all on table public.deep_health_usage_accounts'),
    );
    expect(
      migration,
      contains('revoke all on table public.deep_health_usage_reservations'),
    );
  });

  test('reserve RPC is authenticated, atomic, and expires abandoned work', () {
    expect(
      migration,
      contains('reserve_deep_health_assessment_usage'),
    );
    expect(migration, contains('security definer'));
    expect(migration, contains('set search_path = pg_catalog, public'));
    expect(migration, contains('auth.uid()'));
    expect(migration, contains('for update'));
    expect(migration, contains("status = 'expired'"));
    expect(migration, contains("interval '15 minutes'"));
    expect(migration, contains("reservation.status = 'committed'"));
    expect(migration, contains("reservation.status = 'reserved'"));
  });

  test('commit and release bind every reservation to auth user', () {
    expect(
      migration,
      contains('commit_deep_health_assessment_usage'),
    );
    expect(
      migration,
      contains('release_deep_health_assessment_usage'),
    );
    expect(
      RegExp(
        r'reservation\.user_id = v_user_id',
      ).allMatches(migration).length,
      greaterThanOrEqualTo(4),
    );
    expect(migration, contains("set status = 'committed'"));
    expect(migration, contains("set status = 'released'"));
  });

  test('only authenticated clients can execute quota RPCs', () {
    expect(
      migration,
      contains(
        'revoke all on function '
        'public.reserve_deep_health_assessment_usage() '
        'from public, anon',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function '
        'public.reserve_deep_health_assessment_usage()',
      ),
    );
    expect(migration, contains('to authenticated'));
  });

  test('server gate is not activated in runtime composition yet', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mainSource,
      isNot(contains('SupabaseDeepHealthAssessmentGateService')),
    );
    expect(
      mainSource,
      isNot(contains('supabase_deep_health_assessment_gate_service')),
    );
  });
}
