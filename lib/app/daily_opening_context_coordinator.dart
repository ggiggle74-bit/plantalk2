import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/daily_keywords/supabase_daily_keyword_source.dart';
import '../dialogue/daily_keywords/adapters/local_daily_keyword_source_adapter.dart';
import '../dialogue/daily_keywords/daily_opening_context_provider.dart';
import '../dialogue/daily_keywords/daily_opening_context_provider_factory.dart';
import '../dialogue/daily_keywords/daily_opening_keyword_selector.dart';
import '../dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import '../dialogue/daily_keywords/models/daily_opening_context.dart';

class DailyOpeningContextCoordinator {
  const DailyOpeningContextCoordinator({required this.provider});

  factory DailyOpeningContextCoordinator.supabase({
    SupabaseClient? client,
    Duration timeout = const Duration(seconds: 2),
    DailyOpeningKeywordSelector selector =
        const DailyOpeningKeywordSelector(),
  }) {
    final resolvedClient = client ?? Supabase.instance.client;
    return DailyOpeningContextCoordinator(
      provider: DailyOpeningContextProviderFactory.withFallback(
        primary: SupabaseDailyKeywordSource.fromClient(
          resolvedClient,
          timeout: timeout,
        ),
        fallback: const LocalDailyKeywordSourceAdapter(),
        selector: selector,
      ),
    );
  }

  final DailyOpeningContextProvider provider;

  Future<DailyOpeningContext?> loadForChat({
    required DateTime date,
    required String locale,
    required String plantKey,
    String regionCode = 'global',
    Iterable<String> weatherSignals = const [],
  }) {
    return provider.load(
      request: DailyKeywordSourceRequest(
        date: date,
        locale: locale,
        regionCode: regionCode,
        weatherSignals: weatherSignals,
      ),
      isOpeningTurn: true,
      seed: _stableSeed(
        date: date,
        locale: locale,
        regionCode: regionCode,
        plantKey: plantKey,
      ),
    );
  }

  static int _stableSeed({
    required DateTime date,
    required String locale,
    required String regionCode,
    required String plantKey,
  }) {
    var hash = date.year * 10000 + date.month * 100 + date.day;
    for (final codeUnit
        in '${locale.trim()}|${regionCode.trim()}|${plantKey.trim()}'
            .codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
