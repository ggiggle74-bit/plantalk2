import '../../models/latest_condition_memory.dart';
import '../daily_keywords/models/daily_conversation_material_context.dart';
import '../daily_keywords/models/daily_opening_context.dart';
import 'conversation_usage_ledger.dart';
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
    this.dailyConversationMaterialContext,
    this.dailyOpeningContext,
    this.usageLedger,
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
  final DailyConversationMaterialContext? dailyConversationMaterialContext;
  final DailyOpeningContext? dailyOpeningContext;
  final ConversationUsageLedger? usageLedger;
  final bool isOpeningTurn;
  final UserRegionContext? userRegionContext;
}
