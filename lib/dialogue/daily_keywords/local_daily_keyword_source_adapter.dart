import '../models/daily_keyword_context.dart';
import 'daily_keyword_source.dart';
import 'local_daily_keyword_source.dart';
import 'models/daily_keyword_source_request.dart';

class LocalDailyKeywordSourceAdapter implements DailyKeywordSource {
  const LocalDailyKeywordSourceAdapter({
    this.source = const LocalDailyKeywordSource(),
  });

  final LocalDailyKeywordSource source;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) {
    return Future<DailyKeywordContext>.value(
      source.buildContext(
        date: request.date,
        locale: request.locale,
        weatherSignals: request.weatherSignals,
      ),
    );
  }
}
