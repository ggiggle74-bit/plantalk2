import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/dialogue/supabase_gemini_conversation_engine.dart';
import '../dialogue/chat_panel_conversation_controller.dart';
import '../dialogue/conversation_orchestrator.dart';

class PlantChatConversationControllerFactory {
  const PlantChatConversationControllerFactory._();

  static ChatPanelConversationController supabase({
    SupabaseClient? client,
    Duration timeout = const Duration(seconds: 9),
  }) {
    final resolvedClient = client ?? Supabase.instance.client;
    return ChatPanelConversationController(
      conversationOrchestrator: ConversationOrchestrator(
        apiConversationEngine: SupabaseGeminiConversationEngine.fromClient(
          resolvedClient,
          timeout: timeout,
        ),
      ),
    );
  }
}
