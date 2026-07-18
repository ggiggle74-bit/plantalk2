import 'daily_keyword_source.dart';
import 'daily_opening_keyword_selector.dart';
import 'models/daily_keyword_source_request.dart';
import 'models/daily_opening_context.dart';

class DailyOpeningContextProvider {
  const DailyOpeningContextProvider({
    required this.source,
    this.selector = const DailyOpeningKeywordSelector(),
  });

  final DailyKeywordSource source;
  final DailyOpeningKeywordSelector selector;

  Future<DailyOpeningContext?> load({
    required DailyKeywordSourceRequest request,
    required bool isOpeningTurn,
    required int seed,
  }) async {
    if (!isOpeningTurn) {
      return null;
    }

    try {
      final context = await source.load(request);
      return selector.project(
        context: context,
        now: request.date,
        isOpeningTurn: true,
        seed: seed,
      );
    } catch (_) {
      return null;
    }
  }
}
