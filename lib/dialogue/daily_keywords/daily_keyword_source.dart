import '../models/daily_keyword_context.dart';
import 'models/daily_keyword_source_request.dart';

abstract class DailyKeywordSource {
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request);
}
