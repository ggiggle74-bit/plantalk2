import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/catalogs/calendar_keyword_catalog.dart';

void main() {
  test(
    'generates each supported Korean fixed commemorative day only on its date',
    () {
      expect(_keywords(DateTime.utc(2026, 4, 5), 'ko-KR'), ['식목일']);
      expect(_keywords(DateTime.utc(2026, 5, 5), 'ko'), ['어린이날']);
      expect(_keywords(DateTime.utc(2026, 5, 15), 'KO-kr'), ['스승의날']);
      expect(_keywords(DateTime.utc(2026, 4, 6), 'ko-KR'), isEmpty);
    },
  );

  test('does not emit Korean commemorative days for non-Korean locales', () {
    expect(_keywords(DateTime.utc(2026, 4, 5), 'en-US'), isEmpty);
  });

  test('is deterministic for the same date and locale', () {
    final date = DateTime.utc(2026, 5, 15);
    expect(
      CalendarKeywordCatalog.candidatesFor(date: date, locale: 'ko-KR'),
      CalendarKeywordCatalog.candidatesFor(date: date, locale: 'ko-KR'),
    );
  });
}

List<String> _keywords(DateTime date, String locale) {
  return CalendarKeywordCatalog.candidatesFor(
    date: date,
    locale: locale,
  ).map((candidate) => candidate.keyword).toList();
}
