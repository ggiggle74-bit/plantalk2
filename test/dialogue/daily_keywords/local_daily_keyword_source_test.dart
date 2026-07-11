import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_extractor.dart';
import 'package:plantalk2/dialogue/daily_keywords/local_daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_extraction_result.dart';

void main() {
  test('converts accepted candidates into DailyKeywordContext metadata', () {
    const source = LocalDailyKeywordSource();
    final date = DateTime.utc(2026, 1, 10);

    final context = source.buildContext(
      date: date,
      locale: 'en-US',
      weatherSignals: const ['비'],
    );

    final entry = context.keywords.single;
    expect(context.date, date);
    expect(context.locale, 'en-US');
    expect(context.sourceVersion, LocalDailyKeywordSource.sourceVersion);
    expect(entry.type, DailyKeywordTypes.weather);
    expect(entry.keyword, '비');
    expect(entry.plantHint, '창가 빛 변화를 살피기');
    expect(entry.tone, DailyKeywordTones.gentle);
    expect(entry.fitScore, 0.75);
    expect(entry.relevanceScore, isNull);
  });

  test('returns an empty valid context when no candidates are available', () {
    const source = LocalDailyKeywordSource();
    final date = DateTime.utc(2026, 1, 10);

    final context = source.buildContext(date: date, locale: 'en-US');

    expect(context.date, date);
    expect(context.locale, 'en-US');
    expect(context.sourceVersion, LocalDailyKeywordSource.sourceVersion);
    expect(context.keywords, isEmpty);
  });

  test('contains extractor failures and returns an empty context', () {
    const source = LocalDailyKeywordSource(extractor: _ThrowingExtractor());
    final date = DateTime.utc(2026, 4, 5);

    final context = source.buildContext(
      date: date,
      locale: 'ko-KR',
      weatherSignals: const ['비'],
    );

    expect(context.date, date);
    expect(context.locale, 'ko-KR');
    expect(context.sourceVersion, LocalDailyKeywordSource.sourceVersion);
    expect(context.keywords, isEmpty);
  });
}

class _ThrowingExtractor extends DailyKeywordExtractor {
  const _ThrowingExtractor();

  @override
  DailyKeywordExtractionResult extract(
    Iterable<DailyKeywordCandidate> candidates,
  ) {
    throw StateError('test extractor failure');
  }
}
