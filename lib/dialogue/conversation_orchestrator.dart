import 'engines/api_conversation_engine.dart';
import 'engines/condition_memory_conversation_engine.dart';
import 'engines/fallback_conversation_engine.dart';
import 'engines/local_casual_conversation_engine.dart';
import 'models/conversation_request.dart';
import 'models/conversation_response.dart';
import 'models/conversation_route.dart';
import 'routing/conversation_intent_router.dart';

class ConversationOrchestrator {
  const ConversationOrchestrator({
    this.router = const ConversationIntentRouter(),
    this.localCasualEngine = const LocalCasualConversationEngine(),
    this.conditionMemoryEngine = const ConditionMemoryConversationEngine(),
    this.apiConversationEngine,
    this.fallbackEngine = const FallbackConversationEngine(),
  });

  final ConversationIntentRouter router;
  final LocalCasualConversationEngine localCasualEngine;
  final ConditionMemoryConversationEngine conditionMemoryEngine;
  final ApiConversationEngine? apiConversationEngine;
  final FallbackConversationEngine fallbackEngine;

  Future<ConversationResponse> respond(ConversationRequest request) async {
    final route = router.route(request);

    switch (route) {
      case ConversationRoute.localCasual:
        return localCasualEngine.generate(request);
      case ConversationRoute.conditionMemory:
        return conditionMemoryEngine.generate(request) ??
            fallbackEngine.generate(
              request,
              route: ConversationRoute.conditionMemory,
              debugReason: 'condition_memory_unavailable',
            );
      case ConversationRoute.api:
        final apiEngine = apiConversationEngine;
        if (apiEngine == null) {
          return fallbackEngine.generate(
            request,
            route: ConversationRoute.api,
            debugReason: 'api_engine_unavailable',
          );
        }
        return apiEngine.generate(request);
      case ConversationRoute.fallback:
        return fallbackEngine.generate(request);
    }
  }
}
