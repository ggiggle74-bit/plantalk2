import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String workflow;

  setUpAll(() {
    workflow = File(
      '../../.github/workflows/daily-context-collector.yml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
  });

  test('CR-2I schedules the collector in the Korea time zone', () {
    expect(workflow, contains("cron: '17 1 * * *'"));
    expect(workflow, contains("timezone: 'Asia/Seoul'"));
    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains('MANUAL_COLLECTION_DATE:'));
  });

  test('CR-2I keeps workflow permissions read-only', () {
    expect(workflow, contains('permissions:\n  contents: read'));
    expect(workflow, isNot(contains('contents: write')));
    expect(workflow, isNot(contains('issues: write')));
    expect(workflow, contains('persist-credentials: false'));
  });

  test('CR-2I injects secrets without checking values into source', () {
    expect(
      workflow,
      contains(
        r'KAKAO_REST_API_KEY: ${{ secrets.KAKAO_REST_API_KEY }}',
      ),
    );
    expect(
      workflow,
      contains(r'SUPABASE_URL: ${{ secrets.SUPABASE_URL }}'),
    );
    expect(
      workflow,
      contains(
        r'SUPABASE_SECRET_KEY: ${{ secrets.SUPABASE_SECRET_KEY }}',
      ),
    );
    expect(workflow, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
    expect(workflow, isNot(contains('qyhstykoshvdyhzknqmn')));
  });

  test('CR-2I validates before a bounded persisted collection', () {
    expect(workflow, contains('timeout-minutes: 15'));
    expect(workflow, contains('dart analyze'));
    expect(workflow, contains('dart test'));
    expect(
      workflow,
      contains('--source-version=collector-cr2j1'),
    );
    expect(workflow, contains('--persist'));
    expect(workflow, contains('ref: plant-personality-mvp'));
  });

  test('CR-2I turns runtime failures into observable checks', () {
    expect(workflow, contains('if: failure()'));
    expect(workflow, contains('GITHUB_STEP_SUMMARY'));
    expect(workflow, contains('Collector completed without persisting'));
    expect(workflow, contains('::error::'));
    expect(workflow, contains('::warning::'));
  });
}
