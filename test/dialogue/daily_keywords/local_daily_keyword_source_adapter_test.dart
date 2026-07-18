import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/local_daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/local_daily_keyword_source_adapter.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';

void main() {
  test('adapts the local builder to the asynchronous source contract', () async {
    const adapter = LocalDailyKeywordSourceAdapter();
    final date = DateTime.utc(2026, 1, 10);
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
      weatherSignals: const ['비'],
    );

    final context = await adapter.load(request);

    expect(context.date, date);
    expect(context.locale, 'ko-KR');
    expect(context.sourceVersion, LocalDailyKeywordSource.sourceVersion);
    expect(context.keywords.map((entry) => entry.keyword), contains('비'));
  });

  test('forwards an empty weather signal list without throwing', () async {
    const adapter = LocalDailyKeywordSourceAdapter();
    final request = DailyKeywordSourceRequest(
      date: DateTime.utc(2026, 1, 10),
      locale: 'en-US',
    );

    final context = await adapter.load(request);

    expect(context.date, request.date);
    expect(context.locale, request.locale);
    expect(context.sourceVersion, LocalDailyKeywordSource.sourceVersion);
  });
}
