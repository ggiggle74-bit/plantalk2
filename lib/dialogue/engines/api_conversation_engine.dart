import '../models/conversation_request.dart';
import '../models/conversation_response.dart';

abstract class ApiConversationEngine {
  Future<ConversationResponse> generate(ConversationRequest request);
}
