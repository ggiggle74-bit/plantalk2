import '../models/daily_keyword_context.dart';
import 'daily_keyword_source.dart';
import 'models/daily_keyword_source_request.dart';

class FallbackDailyKeywordSource implements DailyKeywordSource {
  const FallbackDailyKeywordSource({
    required this.primary,
    required this.fallback,
  });

  final DailyKeywordSource primary;
  final DailyKeywordSource fallback;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) async {
    try {
      final primaryContext = await primary.load(request);
      if (primaryContext.hasKeywords) {
        return primaryContext;
      }
    } catch (_) {
      // Continue to the fallback source.
    }

    try {
      return await fallback.load(request);
    } catch (_) {
      return DailyKeywordContext(
        date: request.date,
        locale: request.locale,
        keywords: const [],
      );
    }
  }
}
