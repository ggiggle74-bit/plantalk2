import '../../models/latest_condition_memory.dart';
import 'daily_keyword_context.dart';
import 'user_region_context.dart';

class ConversationRequest {
  const ConversationRequest({
    required this.plantId,
    required this.plantName,
    required this.userMessage,
    this.species,
    this.mood,
    this.friendship,
    this.visitCount,
    this.now,
    this.locale = 'ko',
    this.latestConditionMemory,
    this.dailyKeywordContext,
    this.userRegionContext,
  });

  final String plantId;
  final String plantName;
  final String userMessage;
  final String? species;
  final String? mood;
  final int? friendship;
  final int? visitCount;
  final DateTime? now;
  final String locale;
  final LatestConditionMemory? latestConditionMemory;
  final DailyKeywordContext? dailyKeywordContext;
  final UserRegionContext? userRegionContext;
}
