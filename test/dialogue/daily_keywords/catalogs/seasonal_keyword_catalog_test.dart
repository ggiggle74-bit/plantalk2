import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/catalogs/seasonal_keyword_catalog.dart';

void main() {
  test('uses deterministic month-based Korean seasons', () {
    expect(_keyword(3), '봄');
    expect(_keyword(5), '봄');
    expect(_keyword(6), '여름');
    expect(_keyword(8), '여름');
    expect(_keyword(9), '가을');
    expect(_keyword(11), '가을');
    expect(_keyword(12), '겨울');
    expect(_keyword(2), '겨울');
  });

  test('does not emit Korean seasonal candidates for non-Korean locales', () {
    expect(
      SeasonalKeywordCatalog.candidatesFor(
        date: DateTime.utc(2026, 3, 1),
        locale: 'en-US',
      ),
      isEmpty,
    );
  });

  test('is deterministic for the same date and locale', () {
    final date = DateTime.utc(2026, 9, 1);
    expect(
      SeasonalKeywordCatalog.candidatesFor(date: date, locale: 'ko-KR'),
      SeasonalKeywordCatalog.candidatesFor(date: date, locale: 'ko-KR'),
    );
  });
}

String _keyword(int month) {
  return SeasonalKeywordCatalog.candidatesFor(
    date: DateTime.utc(2026, month, 1),
    locale: 'ko-KR',
  ).single.keyword;
}
