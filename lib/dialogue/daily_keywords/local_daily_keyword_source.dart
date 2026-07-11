import '../models/daily_keyword_context.dart';
import 'catalogs/calendar_keyword_catalog.dart';
import 'catalogs/seasonal_keyword_catalog.dart';
import 'catalogs/weather_keyword_catalog.dart';
import 'daily_keyword_extractor.dart';
import 'models/daily_keyword_candidate.dart';

class LocalDailyKeywordSource {
  const LocalDailyKeywordSource({
    this.extractor = const DailyKeywordExtractor(),
  });

  static const sourceVersion = 'cr1-static-v1';

  final DailyKeywordExtractor extractor;

  DailyKeywordContext buildContext({
    required DateTime date,
    required String locale,
    Iterable<String> weatherSignals = const [],
  }) {
    try {
      final candidates = <DailyKeywordCandidate>[
        ...WeatherKeywordCatalog.candidatesFor(weatherSignals),
        ...CalendarKeywordCatalog.candidatesFor(date: date, locale: locale),
        ...SeasonalKeywordCatalog.candidatesFor(date: date, locale: locale),
      ];
      final result = extractor.extract(candidates);
      if (!result.hasCandidates) {
        return _emptyContext(date: date, locale: locale);
      }

      return DailyKeywordContext(
        date: date,
        locale: locale,
        sourceVersion: result.sourceVersion,
        keywords: result.acceptedCandidates
            .map(
              (candidate) => DailyKeywordEntry(
                type: candidate.type,
                keyword: candidate.keyword,
                hint: candidate.hint,
                category: candidate.category,
                plantHint: candidate.plantHint,
                tone: candidate.tone,
                fitScore: candidate.fitScore,
              ),
            )
            .toList(),
      );
    } catch (_) {
      return _emptyContext(date: date, locale: locale);
    }
  }

  DailyKeywordContext _emptyContext({
    required DateTime date,
    required String locale,
  }) {
    return DailyKeywordContext(
      date: date,
      locale: locale,
      sourceVersion: sourceVersion,
      keywords: const [],
    );
  }
}
