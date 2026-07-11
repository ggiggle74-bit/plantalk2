import '../../models/daily_keyword_context.dart';
import '../daily_keyword_source.dart';
import '../local_daily_keyword_source.dart';
import '../models/daily_keyword_source_request.dart';

class LocalDailyKeywordSourceAdapter implements DailyKeywordSource {
  const LocalDailyKeywordSourceAdapter({
    this.localSource = const LocalDailyKeywordSource(),
  });

  final LocalDailyKeywordSource localSource;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) async {
    return localSource.buildContext(
      date: request.date,
      locale: request.locale,
      weatherSignals: request.weatherSignals,
    );
  }
}
