import '../../models/latest_condition_memory.dart';
import '../daily_keywords/models/daily_opening_context.dart';
import 'daily_keyword_context.dart';
import 'user_region_context.dart';

class ConversationRequest {
  const ConversationRequest({
    required this.plantId,
    required this.plantName,
    required this.userMessage,
    this.previousUserMessage,
    this.previousPlantReply,
    this.species,
    this.mood,
    this.friendship,
    this.visitCount,
    this.now,
    this.locale = 'ko',
    this.latestConditionMemory,
    this.dailyKeywordContext,
    this.dailyOpeningContext,
    this.isOpeningTurn = false,
    this.userRegionContext,
  });

  final String plantId;
  final String plantName;
  final String userMessage;
  final String? previousUserMessage;
  final String? previousPlantReply;
  final String? species;
  final String? mood;
  final int? friendship;
  final int? visitCount;
  final DateTime? now;
  final String locale;
  final LatestConditionMemory? latestConditionMemory;
  final DailyKeywordContext? dailyKeywordContext;
  final DailyOpeningContext? dailyOpeningContext;
  final bool isOpeningTurn;
  final UserRegionContext? userRegionContext;
}
