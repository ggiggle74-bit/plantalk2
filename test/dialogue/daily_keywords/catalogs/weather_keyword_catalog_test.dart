import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/catalogs/weather_keyword_catalog.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';

void main() {
  test('whitelist entries have complete safe metadata', () {
    expect(
      WeatherKeywordCatalog.entries.map((entry) => entry.keyword),
      containsAll(<String>['건조', '습도', '비', '장맛비', '폭염', '한파', '강풍', '미세먼지']),
    );

    for (final entry in WeatherKeywordCatalog.entries) {
      expect(entry.keyword.trim(), isNotEmpty);
      expect(entry.hint.trim(), isNotEmpty);
      expect(entry.plantHint.trim(), isNotEmpty);
      expect(DailyKeywordTones.allowed, contains(entry.tone));
      expect(entry.fitScore.isFinite, isTrue);
      expect(entry.fitScore, inInclusiveRange(0.0, 1.0));
      expect(entry.type, DailyKeywordTypes.weather);
      expect(entry.category, isNotEmpty);
    }
  });

  test('matches only normalized supplied weather signals in stable order', () {
    final candidates = WeatherKeywordCatalog.candidatesFor([
      '  건조  ',
      '건조',
      '',
      '알 수 없는 신호',
      '습도',
    ]);

    expect(candidates.map((candidate) => candidate.keyword), ['건조', '습도']);
  });

  test('unknown and empty weather signals produce no candidates', () {
    expect(WeatherKeywordCatalog.candidatesFor(['', '   ', '맑음']), isEmpty);
  });
}
