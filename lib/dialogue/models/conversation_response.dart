import 'conversation_route.dart';

class ConversationResponse {
  const ConversationResponse({
    required this.replyText,
    required this.route,
    this.usedDailyKeyword = false,
    this.usedConditionMemory = false,
    this.usedApi = false,
    this.isFallback = false,
    this.debugReason,
  });

  final String replyText;
  final ConversationRoute route;
  final bool usedDailyKeyword;
  final bool usedConditionMemory;
  final bool usedApi;
  final bool isFallback;
  final String? debugReason;
}
