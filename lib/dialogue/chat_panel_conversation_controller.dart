import '../models/latest_condition_memory.dart';
import '../services/dialogue_service.dart';
import 'conversation_orchestrator.dart';
import 'daily_keywords/models/daily_conversation_material_context.dart';
import 'daily_keywords/models/daily_opening_context.dart';
import 'dialogue_decision_context_builder.dart';
import 'dialogue_engine.dart';
import 'models/conversation_request.dart';
import 'models/conversation_route.dart';
import 'models/conversation_usage_ledger.dart';

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
    this.previousPlantReply,
    this.latestConditionMemory,
    this.conditionMemoryReplyCount = 0,
    this.fetchDialogueReply,
    this.dailyOpeningContext,
    this.dailyConversationMaterialContext,
    this.usageLedger,
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
  final String? previousPlantReply;
  final LatestConditionMemory? latestConditionMemory;
  final int conditionMemoryReplyCount;
  final ChatPanelDialogueReplyFetcher? fetchDialogueReply;
  final DailyOpeningContext? dailyOpeningContext;
  final DailyConversationMaterialContext? dailyConversationMaterialContext;
  final ConversationUsageLedger? usageLedger;
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
  static const conditionMemoryUnavailableReply =
      '우리 최근 일주일 동안은 상태를 같이 확인하지 않았네. 지금 사진으로 한번 봐줄래?';

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
    final conversationRequest = _conversationRequest(request);
    final route = _conversationOrchestrator.router.route(conversationRequest);
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

    if (route == ConversationRoute.api) {
      final apiReply = await _orchestratorReply(conversationRequest, route);
      return ChatPanelConversationResponse(
        replyText: (apiReply ?? fallbackReply).trim(),
        conditionMemoryReplyCount: request.conditionMemoryReplyCount,
      );
    }

    if (route == ConversationRoute.conditionMemory &&
        request.latestConditionMemory == null) {
      return ChatPanelConversationResponse(
        replyText: conditionMemoryUnavailableReply,
        conditionMemoryReplyCount: request.conditionMemoryReplyCount,
      );
    }

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
      final orchestratorReply = await _orchestratorReply(
        conversationRequest,
        route,
      );
      if (orchestratorReply != null) {
        reply = orchestratorReply;
      }
    }

    reply = reply.trim();

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

  ConversationRequest _conversationRequest(
    ChatPanelConversationRequest request,
  ) {
    return ConversationRequest(
      plantId: _conversationPlantId(request),
      plantName: request.plantName,
      userMessage: request.userMessage,
      previousUserMessage: request.previousPlantReply == null
          ? null
          : request.previousUserMessage,
      previousPlantReply: request.previousPlantReply,
      species: request.speciesDisplayName,
      mood: request.mood,
      friendship: request.friendship,
      now: request.now,
      latestConditionMemory: request.latestConditionMemory,
      dailyConversationMaterialContext:
          request.dailyConversationMaterialContext,
      dailyOpeningContext: request.dailyOpeningContext,
      usageLedger: request.usageLedger,
      isOpeningTurn: request.isOpeningTurn,
    );
  }

  Future<String?> _orchestratorReply(
    ConversationRequest request,
    ConversationRoute route,
  ) async {
    if (route == ConversationRoute.fallback) {
      return null;
    }

    final response = await _conversationOrchestrator.respondForRoute(
      request,
      route,
    );

    if (response.route != route ||
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
