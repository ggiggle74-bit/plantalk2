import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/daily_keywords/supabase_daily_keyword_source.dart';
import '../dialogue/daily_keywords/adapters/local_daily_keyword_source_adapter.dart';
import '../dialogue/daily_keywords/daily_conversation_material_projector.dart';
import '../dialogue/daily_keywords/daily_keyword_source.dart';
import '../dialogue/daily_keywords/daily_opening_context_provider.dart';
import '../dialogue/daily_keywords/daily_opening_keyword_selector.dart';
import '../dialogue/daily_keywords/fallback_daily_keyword_source.dart';
import '../dialogue/daily_keywords/models/daily_conversation_material_context.dart';
import '../dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import '../dialogue/daily_keywords/models/daily_opening_context.dart';

class DailyChatContextBundle {
  const DailyChatContextBundle({
    this.openingContext,
    this.materialContext,
  });

  final DailyOpeningContext? openingContext;
  final DailyConversationMaterialContext? materialContext;
}

class DailyOpeningContextCoordinator {
  const DailyOpeningContextCoordinator({required this.provider})
    : source = null,
      openingSelector = const DailyOpeningKeywordSelector(),
      materialProjector = const DailyConversationMaterialProjector();

  const DailyOpeningContextCoordinator.fromSource({
    required this.source,
    this.openingSelector = const DailyOpeningKeywordSelector(),
    this.materialProjector = const DailyConversationMaterialProjector(),
  }) : provider = null;

  factory DailyOpeningContextCoordinator.supabase({
    SupabaseClient? client,
    Duration timeout = const Duration(seconds: 2),
    DailyOpeningKeywordSelector selector =
        const DailyOpeningKeywordSelector(),
    DailyConversationMaterialProjector materialProjector =
        const DailyConversationMaterialProjector(),
  }) {
    final resolvedClient = client ?? Supabase.instance.client;
    final source = FallbackDailyKeywordSource(
      primary: SupabaseDailyKeywordSource.fromClient(
        resolvedClient,
        timeout: timeout,
      ),
      fallback: const LocalDailyKeywordSourceAdapter(),
    );

    return DailyOpeningContextCoordinator.fromSource(
      source: source,
      openingSelector: selector,
      materialProjector: materialProjector,
    );
  }

  final DailyOpeningContextProvider? provider;
  final DailyKeywordSource? source;
  final DailyOpeningKeywordSelector openingSelector;
  final DailyConversationMaterialProjector materialProjector;

  Future<DailyOpeningContext?> loadForChat({
    required DateTime date,
    required String locale,
    required String plantKey,
    String regionCode = 'global',
    Iterable<String> weatherSignals = const [],
  }) async {
    final currentProvider = provider;
    if (currentProvider != null) {
      return currentProvider.load(
        request: _request(
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

    final bundle = await loadSessionForChat(
      date: date,
      locale: locale,
      plantKey: plantKey,
      regionCode: regionCode,
      weatherSignals: weatherSignals,
    );
    return bundle.openingContext;
  }

  Future<DailyChatContextBundle> loadSessionForChat({
    required DateTime date,
    required String locale,
    required String plantKey,
    String regionCode = 'global',
    Iterable<String> weatherSignals = const [],
  }) async {
    final request = _request(
      date: date,
      locale: locale,
      regionCode: regionCode,
      weatherSignals: weatherSignals,
    );
    final seed = _stableSeed(
      date: date,
      locale: locale,
      regionCode: regionCode,
      plantKey: plantKey,
    );
    final currentSource = source;

    if (currentSource == null) {
      final currentProvider = provider;
      final openingContext = currentProvider == null
          ? null
          : await currentProvider.load(
              request: request,
              isOpeningTurn: true,
              seed: seed,
            );
      return DailyChatContextBundle(openingContext: openingContext);
    }

    try {
      final context = await currentSource.load(request);
      return DailyChatContextBundle(
        openingContext: openingSelector.project(
          context: context,
          now: date,
          isOpeningTurn: true,
          seed: seed,
        ),
        materialContext: materialProjector.project(
          context: context,
          now: date,
        ),
      );
    } catch (_) {
      return const DailyChatContextBundle();
    }
  }

  static DailyKeywordSourceRequest _request({
    required DateTime date,
    required String locale,
    required String regionCode,
    required Iterable<String> weatherSignals,
  }) {
    return DailyKeywordSourceRequest(
      date: date,
      locale: locale,
      regionCode: regionCode,
      weatherSignals: weatherSignals,
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
