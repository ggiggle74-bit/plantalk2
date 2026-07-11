import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/adapters/local_daily_keyword_source_adapter.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_extractor.dart';
import 'package:plantalk2/dialogue/daily_keywords/local_daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_extraction_result.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  test(
    'forwards request values and returns the local context unchanged',
    () async {
      final date = DateTime.utc(2026, 7, 8);
      final context = DailyKeywordContext(
        date: date,
        locale: 'ko-KR',
        generatedAt: DateTime.utc(2026, 7, 8, 1),
        sourceVersion: 'local-test-v1',
        keywords: const [
          DailyKeywordEntry(type: 'weather', keyword: '비', hint: '비가 내리는 날'),
        ],
      );
      final localSource = _RecordingLocalDailyKeywordSource(context);
      final adapter = LocalDailyKeywordSourceAdapter(localSource: localSource);
      final request = DailyKeywordSourceRequest(
        date: date,
        locale: 'ko-KR',
        weatherSignals: const ['비', '장맛비'],
      );

      final result = await adapter.load(request);

      expect(result, same(context));
      expect(localSource.receivedDate, date);
      expect(localSource.receivedLocale, 'ko-KR');
      expect(localSource.receivedWeatherSignals, ['비', '장맛비']);
      expect(result.sourceVersion, 'local-test-v1');
      expect(result.generatedAt, DateTime.utc(2026, 7, 8, 1));
    },
  );

  test('preserves the existing local empty-context policy', () async {
    const adapter = LocalDailyKeywordSourceAdapter();
    final date = DateTime.utc(2026, 1, 10);

    final context = await adapter.load(
      DailyKeywordSourceRequest(date: date, locale: 'en-US'),
    );

    expect(context.date, date);
    expect(context.locale, 'en-US');
    expect(context.sourceVersion, LocalDailyKeywordSource.sourceVersion);
    expect(context.generatedAt, isNull);
    expect(context.keywords, isEmpty);
  });

  test('preserves the existing local extractor-failure policy', () async {
    const adapter = LocalDailyKeywordSourceAdapter(
      localSource: LocalDailyKeywordSource(extractor: _ThrowingExtractor()),
    );
    final date = DateTime.utc(2026, 7, 8);

    final context = await adapter.load(
      DailyKeywordSourceRequest(
        date: date,
        locale: 'ko-KR',
        weatherSignals: const ['비'],
      ),
    );

    expect(context.date, date);
    expect(context.locale, 'ko-KR');
    expect(context.sourceVersion, LocalDailyKeywordSource.sourceVersion);
    expect(context.generatedAt, isNull);
    expect(context.keywords, isEmpty);
  });
}

class _RecordingLocalDailyKeywordSource extends LocalDailyKeywordSource {
  _RecordingLocalDailyKeywordSource(this.context);

  final DailyKeywordContext context;
  DateTime? receivedDate;
  String? receivedLocale;
  List<String>? receivedWeatherSignals;

  @override
  DailyKeywordContext buildContext({
    required DateTime date,
    required String locale,
    Iterable<String> weatherSignals = const [],
  }) {
    receivedDate = date;
    receivedLocale = locale;
    receivedWeatherSignals = List.of(weatherSignals);
    return context;
  }
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
