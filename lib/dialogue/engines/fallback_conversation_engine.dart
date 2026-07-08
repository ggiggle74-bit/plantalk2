import '../models/conversation_request.dart';
import '../models/conversation_response.dart';
import '../models/conversation_route.dart';

class FallbackConversationEngine {
  const FallbackConversationEngine();

  ConversationResponse generate(
    ConversationRequest request, {
    ConversationRoute route = ConversationRoute.fallback,
    String? debugReason,
  }) {
    return ConversationResponse(
      replyText: '그건 내가 조금 더 배워야 자연스럽게 말할 수 있어. 대신 지금 상태나 사진 이야기는 같이 볼 수 있어.',
      route: route,
      isFallback: true,
      debugReason: debugReason,
    );
  }
}
