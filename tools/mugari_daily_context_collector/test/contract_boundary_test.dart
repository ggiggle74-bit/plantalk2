import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  test('CR-2B core has no UI, IO, network, storage, or scheduler dependency', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    const forbiddenSnippets = [
      'dart:html',
      'dart:io',
      'package:flutter',
      'package:http',
      'platform.environment',
      'supabase',
      'kakao',
      'dapi.kakao.com',
      'crawler',
      'scheduler',
    ];

    for (final file in dartFiles) {
      final source = file.readAsStringSync().toLowerCase();
      for (final snippet in forbiddenSnippets) {
        expect(
          source,
          isNot(contains(snippet)),
          reason: '${file.path} must not reference $snippet in CR-2B',
        );
      }
    }
  });

  test('checked-in example satisfies the executable contract', () {
    final source = File(
      'example/daily_keyword_context.json',
    ).readAsStringSync();
    final document = DailyKeywordContextDocument.decode(source);
    final result = const DailyKeywordContractValidator().validate(document);

    expect(result.errors, isEmpty);
    expect(document.keywords, hasLength(3));
    expect(
      document.keywords.expand((keyword) => keyword.conversationAngles),
      isNotEmpty,
    );
  });

  test('JSON Schema and executable model use the same schema version', () {
    final schema = File(
      'schema/daily_keyword_context_v1.schema.json',
    ).readAsStringSync();

    expect(
      schema,
      contains(DailyKeywordContextDocument.currentSchemaVersion),
    );
  });

  test('planned queries stay within the safe deterministic template set', () {
    final plan = const DailyQueryPlanner().plan(
      DailyQueryPlanRequest(
        date: DateTime.utc(2026, 7, 18),
        locale: 'ko-KR',
        regionCode: 'KR-11',
        regionLabel: '서울',
        targetAgeBands: DailyKeywordAgeBands.allowed,
      ),
    );

    expect(plan.queries, isNotEmpty);
    expect(plan.queries.length, lessThanOrEqualTo(9));
    expect(plan.queries.map((query) => query.id).toSet(), hasLength(plan.queries.length));
    expect(
      plan.queries.map((query) => query.text).toSet(),
      hasLength(plan.queries.length),
    );
  });
}
