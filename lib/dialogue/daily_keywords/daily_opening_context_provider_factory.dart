import 'daily_keyword_source.dart';
import 'daily_opening_context_provider.dart';
import 'daily_opening_keyword_selector.dart';
import 'fallback_daily_keyword_source.dart';
import 'local_daily_keyword_source.dart';
import 'local_daily_keyword_source_adapter.dart';

class DailyOpeningContextProviderFactory {
  const DailyOpeningContextProviderFactory._();

  static DailyOpeningContextProvider fromSource({
    required DailyKeywordSource source,
    DailyOpeningKeywordSelector selector =
        const DailyOpeningKeywordSelector(),
  }) {
    return DailyOpeningContextProvider(
      source: source,
      selector: selector,
    );
  }

  static DailyOpeningContextProvider local({
    LocalDailyKeywordSource source = const LocalDailyKeywordSource(),
    DailyOpeningKeywordSelector selector =
        const DailyOpeningKeywordSelector(),
  }) {
    return fromSource(
      source: LocalDailyKeywordSourceAdapter(source: source),
      selector: selector,
    );
  }

  static DailyOpeningContextProvider withFallback({
    required DailyKeywordSource primary,
    required DailyKeywordSource fallback,
    DailyOpeningKeywordSelector selector =
        const DailyOpeningKeywordSelector(),
  }) {
    return fromSource(
      source: FallbackDailyKeywordSource(
        primary: primary,
        fallback: fallback,
      ),
      selector: selector,
    );
  }
}
