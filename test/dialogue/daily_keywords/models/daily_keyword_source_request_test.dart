import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';

void main() {
  test('preserves date, locale, weather signal order, and duplicates', () {
    final date = DateTime.utc(2026, 7, 8);
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
      weatherSignals: const ['비', '건조', '비'],
    );

    expect(request.date, date);
    expect(request.locale, 'ko-KR');
    expect(request.weatherSignals, ['비', '건조', '비']);
  });

  test('defensively copies weather signals and keeps them unmodifiable', () {
    final signals = <String>['비'];
    final request = DailyKeywordSourceRequest(
      date: DateTime.utc(2026, 7, 8),
      locale: 'ko-KR',
      weatherSignals: signals,
    );

    signals.add('폭염');

    expect(request.weatherSignals, ['비']);
    expect(() => request.weatherSignals.add('습도'), throwsUnsupportedError);
  });

  test('allows an empty weather signal list', () {
    final request = DailyKeywordSourceRequest(
      date: DateTime.utc(2026, 7, 8),
      locale: 'en-US',
    );

    expect(request.weatherSignals, isEmpty);
  });
}
