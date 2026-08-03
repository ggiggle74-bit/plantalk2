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

  test('runtime uses the server gate for deep health assessments', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mainSource,
      contains('SupabaseDeepHealthAssessmentGateService'),
    );
    expect(
      mainSource,
      contains('supabase_deep_health_assessment_gate_service'),
    );
  });

  test('reset policy is private, configurable, and applies only recent commits', () {
    final resetMigration = File(
      'supabase/migrations/'
      '20260730090000_deep_health_usage_reset_policy.sql',
    ).readAsStringSync();

    expect(resetMigration, contains('deep_health_usage_policy'));
    expect(resetMigration, contains('default 30'));
    expect(resetMigration, contains('between 1 and 365'));
    expect(resetMigration, contains('enable row level security'));
    expect(
      resetMigration,
      contains('revoke all on table public.deep_health_usage_policy'),
    );
    expect(resetMigration, contains('make_interval(days => v_reset_interval_days)'));
    expect(
      resetMigration,
      contains("reservation.status = 'committed'"),
    );
    expect(resetMigration, contains('reservation.committed_at > v_window_started_at'));
    expect(resetMigration, contains('reset_at timestamptz'));
    final dropIndex = resetMigration.indexOf(
      'drop function if exists public.reserve_deep_health_assessment_usage()',
    );
    final createIndex = resetMigration.indexOf(
      'create function public.reserve_deep_health_assessment_usage()',
    );
    expect(dropIndex, greaterThanOrEqualTo(0));
    expect(createIndex, greaterThan(dropIndex));
  });
}
