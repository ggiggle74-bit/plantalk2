import '../models/latest_condition_memory.dart';
import '../services/dialogue_service.dart';
import 'conversation_orchestrator.dart';
import 'daily_keywords/models/daily_opening_context.dart';
import 'dialogue_decision_context_builder.dart';
import 'dialogue_engine.dart';
import 'models/conversation_request.dart';
import 'models/conversation_route.dart';

typedef ChatPanelDialogueReplyFetcher =
    Future<String?> Function({String? situation, String? conditionKey});

class ChatPanelConversationRequest {
  const ChatPanelConversationRequest({
    required this.plantName,
    required this.userMessage,
    required this.waterDay,
    this.plantId,
    this.speciesDisplayName,
    this.mood,
    this.friendship,
    this.previousUserMessage,
    this.latestConditionMemory,
    this.conditionMemoryReplyCount = 0,
    this.fetchDialogueReply,
    this.dailyOpeningContext,
    this.isOpeningTurn = false,
    this.now,
  });

  final String plantName;
  final String userMessage;
  final int waterDay;
  final String? plantId;
  final String? speciesDisplayName;
  final String? mood;
  final int? friendship;
  final String? previousUserMessage;
  final LatestConditionMemory? latestConditionMemory;
  final int conditionMemoryReplyCount;
  final ChatPanelDialogueReplyFetcher? fetchDialogueReply;
  final DailyOpeningContext? dailyOpeningContext;
  final bool isOpeningTurn;
  final DateTime? now;
}

class ChatPanelConversationResponse {
  const ChatPanelConversationResponse({
    required this.replyText,
    required this.conditionMemoryReplyCount,
  });

  final String replyText;
  final int conditionMemoryReplyCount;
}

class ChatPanelConversationController {
  ChatPanelConversationController({
    DialogueDecisionContextBuilder decisionContextBuilder =
        const DialogueDecisionContextBuilder(),
    DialogueService? dialogueService,
    ConversationOrchestrator? conversationOrchestrator,
  }) : _decisionContextBuilder = decisionContextBuilder,
       _dialogueService = dialogueService,
       _conversationOrchestrator =
           conversationOrchestrator ?? const ConversationOrchestrator();

  final DialogueDecisionContextBuilder _decisionContextBuilder;
  DialogueService? _dialogueService;
  final ConversationOrchestrator _conversationOrchestrator;

  Future<ChatPanelConversationResponse> generateReply(
    ChatPanelConversationRequest request,
  ) async {
    final decisionContext = _decisionContextBuilder.build(
      input: request.userMessage,
      waterDay: request.waterDay,
      plantName: request.plantName,
      previousUserMessage: request.previousUserMessage,
      conditionMemoryContext: request.latestConditionMemory,
      conditionMemoryReplyCount: request.conditionMemoryReplyCount,
      allowConditionMemoryFallback: request.conditionMemoryReplyCount < 2,
    );

    final fallbackReply = DialogueEngine.placeholderReply(
      plantName: request.plantName,
      userMessage: request.userMessage,
      waterDay: request.waterDay,
      situation: decisionContext.situationKey,
      previousUserMessage: request.previousUserMessage,
    );

    var reply = fallbackReply;
    var usedDbReply = false;
    var nextConditionMemoryReplyCount = request.conditionMemoryReplyCount;

    if (decisionContext.hasDetectedSituation ||
        decisionContext.situationKey ==
            PhotoConditionDialogueSituations.conditionCheckRequest) {
      try {
        final dbReply = await _fetchDialogueReply(
          request,
          situation: decisionContext.situationKey,
          conditionKey: decisionContext.conditionKey,
        );

        if (dbReply != null) {
          reply = dbReply;
          usedDbReply = true;
        }
      } catch (_) {
        reply = fallbackReply;
      }
    } else if (decisionContext.usesConditionMemoryFallback) {
      try {
        final dbReply = await _fetchDialogueReply(
          request,
          situation: decisionContext.situationKey,
          conditionKey: decisionContext.conditionKey,
        );

        if (dbReply != null) {
          reply = dbReply;
          usedDbReply = true;
        }
      } catch (_) {
        reply = fallbackReply;
      }

      if (!usedDbReply) {
        final conditionContext = DialogueEngine.photoConditionDialogueContext(
          userMessage: request.userMessage,
          memoryMessage: request.latestConditionMemory?.message,
          memoryEventType: request.latestConditionMemory?.eventType,
          replyCount: request.conditionMemoryReplyCount,
        );
        final conditionMemoryReply = conditionContext == null
            ? null
            : DialogueEngine.conditionMemoryReply(
                plantName: request.plantName,
                waterDay: request.waterDay,
                context: conditionContext,
              );

        if (conditionMemoryReply != null &&
            conditionMemoryReply.trim().isNotEmpty) {
          reply = conditionMemoryReply;
        }
      }

      nextConditionMemoryReplyCount++;
    }

    if (!usedDbReply && !decisionContext.usesConditionMemoryFallback) {
      final orchestratorReply = await _localCasualOrchestratorReply(request);
      if (orchestratorReply != null) {
        reply = orchestratorReply;
      }
    }

    reply = DialogueEngine.applyPlantPersonality(
      reply: reply,
      plantId: request.plantId,
      plantName: request.plantName,
    );

    return ChatPanelConversationResponse(
      replyText: reply,
      conditionMemoryReplyCount: nextConditionMemoryReplyCount,
    );
  }

  Future<String?> _fetchDialogueReply(
    ChatPanelConversationRequest request, {
    String? situation,
    String? conditionKey,
  }) {
    final callback = request.fetchDialogueReply;
    if (callback != null) {
      return callback(situation: situation, conditionKey: conditionKey);
    }

    final dialogueService = _dialogueService ??= DialogueService();
    return dialogueService.fetchRandomReply(
      situation: situation,
      conditionKey: conditionKey,
    );
  }

  Future<String?> _localCasualOrchestratorReply(
    ChatPanelConversationRequest request,
  ) async {
    final conversationRequest = ConversationRequest(
      plantId: _conversationPlantId(request),
      plantName: request.plantName,
      userMessage: request.userMessage,
      species: request.speciesDisplayName,
      mood: request.mood,
      friendship: request.friendship,
      now: request.now,
      latestConditionMemory: request.latestConditionMemory,
      dailyOpeningContext: request.dailyOpeningContext,
      isOpeningTurn: request.isOpeningTurn,
    );

    final route = _conversationOrchestrator.router.route(conversationRequest);
    if (route != ConversationRoute.localCasual) {
      return null;
    }

    final response = await _conversationOrchestrator.respond(
      conversationRequest,
    );

    if (response.route != ConversationRoute.localCasual ||
        response.isFallback ||
        response.replyText.trim().isEmpty) {
      return null;
    }

    return response.replyText;
  }

  String _conversationPlantId(ChatPanelConversationRequest request) {
    final plantId = request.plantId?.trim();
    if (plantId != null && plantId.isNotEmpty) {
      return plantId;
    }

    final plantName = request.plantName.trim();
    return plantName.isEmpty ? 'local-chat-panel-plant' : plantName;
  }
}
