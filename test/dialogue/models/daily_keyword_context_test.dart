import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  test('stores keyword and hint data without plant-specific id', () {
    final context = DailyKeywordContext(
      date: DateTime.utc(2026, 7, 8),
      locale: 'ko',
      generatedAt: DateTime.utc(2026, 7, 8, 1),
      sourceVersion: 'daily-keywords-v1',
      keywords: const [
        DailyKeywordEntry(
          type: 'calendar',
          keyword: '초복',
          hint: '더운 계절을 가볍게 언급하기',
          category: 'seasonal_day',
          relevanceScore: 0.8,
        ),
        DailyKeywordEntry(type: 'weather', keyword: '소나기', hint: '짧은 비 소식'),
      ],
    );

    expect(context.hasKeywords, isTrue);
    expect(context.keywords.first.keyword, '초복');
    expect(context.keywords.first.hint, '더운 계절을 가볍게 언급하기');
    expect(context.pickForSeed(0)?.keyword, '초복');
    expect(context.pickForSeed(1)?.keyword, '소나기');
    expect(context.pickForSeed(-1)?.keyword, '소나기');

    final source = File(
      'lib/dialogue/models/daily_keyword_context.dart',
    ).readAsStringSync().toLowerCase();
    expect(source, isNot(contains('plantid')));
    expect(source, isNot(contains('plant_id')));
  });

  test('daily keyword entry metadata remains optional', () {
    const legacyEntry = DailyKeywordEntry(
      type: 'weather',
      keyword: '비',
      hint: '비가 내리는 날',
    );
    const metadataEntry = DailyKeywordEntry(
      type: 'weather',
      keyword: '장맛비',
      hint: '비가 이어지는 때',
      plantHint: '실내 공기 흐름을 살피기',
      tone: 'cautious',
      fitScore: 0.82,
    );

    expect(legacyEntry.plantHint, isNull);
    expect(legacyEntry.tone, isNull);
    expect(legacyEntry.fitScore, isNull);
    expect(metadataEntry.plantHint, '실내 공기 흐름을 살피기');
    expect(metadataEntry.tone, 'cautious');
    expect(metadataEntry.fitScore, 0.82);
  });
}
