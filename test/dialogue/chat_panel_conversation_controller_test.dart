import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel_conversation_controller.dart';
import 'package:plantalk2/dialogue/conversation_orchestrator.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_response.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  test('DB-authored reply wins over local casual orchestrator', () async {
    const dbMarker = 'DB_REPLY_MARKER 인사야.';
    const orchestratorMarker = 'ORCHESTRATOR_MARKER 인사야.';
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.localCasual,
        replyText: orchestratorMarker,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );
    final requests = <_ReplyRequest>[];

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        fetchDialogueReply: ({situation, conditionKey}) async {
          requests.add(
            _ReplyRequest(situation: situation, conditionKey: conditionKey),
          );
          return dbMarker;
        },
      ),
    );

    expect(requests, hasLength(1));
    expect(requests.single.situation, 'greeting');
    expect(orchestrator.callCount, 0);
    expect(response.replyText, contains(dbMarker));
    expect(response.replyText, isNot(contains(orchestratorMarker)));
    expect(response.conditionMemoryReplyCount, 0);
  });

  test('named knowledge question bypasses greeting DB replies', () async {
    const apiReply = '소행성 충돌과 기후 변화가 큰 원인으로 알려져 있어.';
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.api,
        replyText: apiReply,
        usedApi: true,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );
    var dbCallCount = 0;

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '무가리야 공룡은 왜 멸종했어?',
        waterDay: 0,
        fetchDialogueReply: ({situation, conditionKey}) async {
          dbCallCount++;
          return '왔구나. 기다리고 있었어.';
        },
      ),
    );

    expect(dbCallCount, 0);
    expect(orchestrator.callCount, 1);
    expect(response.replyText, apiReply);
  });

  test('legacy condition-memory path wins over orchestrator', () async {
    const conditionMarker = '사진만으로는 상태를 확실히 판단하기 어려워요.';
    const orchestratorMarker = 'ORCHESTRATOR_MARKER 조건 답변';
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.localCasual,
        replyText: orchestratorMarker,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '초록이',
        userMessage: '상태 어때?',
        waterDay: 0,
        latestConditionMemory: LatestConditionMemory(
          message: conditionMarker,
          eventType: 'uncertain',
        ),
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(orchestrator.callCount, 0);
    expect(response.replyText, contains(conditionMarker));
    expect(response.replyText, isNot(contains(orchestratorMarker)));
    expect(response.conditionMemoryReplyCount, 1);
  });

  test('preserves DB reply without a fixed personality suffix', () async {
    final controller = ChatPanelConversationController();
    const baseReply = 'DB 답변이야.';

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-tone',
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        fetchDialogueReply: ({situation, conditionKey}) async => baseReply,
      ),
    );

    expect(response.replyText, baseReply);
    expect(response.replyText, isNot(contains('작게 말해볼게')));
    expect(response.replyText, isNot(contains('조금 쑥스럽지만')));
  });

  test('local casual orchestrator is used only after DB miss', () async {
    const orchestratorReply = '오케스트레이터가 고른 짧은 인사야.';
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.localCasual,
        replyText: orchestratorReply,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(orchestrator.callCount, 1);
    expect(orchestrator.requests.single.plantId, '무가리');
    expect(orchestrator.requests.single.dailyKeywordContext, isNull);
    expect(response.replyText, orchestratorReply);
    expect(response.conditionMemoryReplyCount, 0);
  });

  test('API-like message uses the orchestrator after a DB miss', () async {
    const orchestratorMarker = 'API_ORCHESTRATOR_MARKER';
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.api,
        replyText: orchestratorMarker,
        usedApi: true,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '몬스테라 분갈이 방법과 흙 배합을 자세히 설명해줘',
        previousUserMessage: '오늘 학교에서 속상한 일이 있었어.',
        previousPlantReply: '무슨 일이 있었어? 천천히 말해줘.',
        waterDay: 0,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(orchestrator.callCount, 1);
    expect(
      orchestrator.requests.single.previousUserMessage,
      '오늘 학교에서 속상한 일이 있었어.',
    );
    expect(
      orchestrator.requests.single.previousPlantReply,
      '무슨 일이 있었어? 천천히 말해줘.',
    );
    expect(response.replyText, contains(orchestratorMarker));
    expect(response.replyText.trim(), isNotEmpty);
    expect(response.conditionMemoryReplyCount, 0);
  });

  test('omits an incomplete prior turn from the API request', () async {
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.api,
        replyText: 'API 답변',
        usedApi: true,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );

    await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '공룡은 왜 멸종했어?',
        previousUserMessage: '최근 상태가 어땠어?',
        waterDay: 0,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(orchestrator.requests.single.previousUserMessage, isNull);
    expect(orchestrator.requests.single.previousPlantReply, isNull);
  });

  test('non-localCasual orchestrator response is ignored', () async {
    const orchestratorMarker = 'NON_LOCAL_ORCHESTRATOR_MARKER';
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.conditionMemory,
        replyText: orchestratorMarker,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(orchestrator.callCount, 1);
    expect(response.replyText, isNot(contains(orchestratorMarker)));
    expect(response.replyText.trim(), isNotEmpty);
    expect(response.conditionMemoryReplyCount, 0);
  });

  test('orchestrator fallback response is ignored', () async {
    const orchestratorMarker = 'ORCHESTRATOR_FALLBACK_MARKER';
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.fallback,
        replyText: orchestratorMarker,
        isFallback: true,
      ),
    );
    final controller = ChatPanelConversationController(
      conversationOrchestrator: orchestrator,
    );

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(orchestrator.callCount, 1);
    expect(response.replyText, isNot(contains(orchestratorMarker)));
    expect(response.replyText.trim(), isNotEmpty);
    expect(response.conditionMemoryReplyCount, 0);
  });

  test(
    'one generateReply call does not concatenate DB and orchestrator replies',
    () async {
      const dbMarker = 'DB_ONLY_MARKER';
      const orchestratorMarker = 'ORCHESTRATOR_ONLY_MARKER';
      final orchestrator = _FakeConversationOrchestrator(
        _orchestratorResponse(
          route: ConversationRoute.localCasual,
          replyText: orchestratorMarker,
        ),
      );
      final controller = ChatPanelConversationController(
        conversationOrchestrator: orchestrator,
      );

      final response = await controller.generateReply(
        ChatPanelConversationRequest(
          plantId: 'plant-1',
          plantName: '무가리',
          userMessage: '안녕',
          waterDay: 0,
          fetchDialogueReply: ({situation, conditionKey}) async => dbMarker,
        ),
      );

      expect(orchestrator.callCount, 0);
      expect(response.replyText, contains(dbMarker));
      expect(response.replyText, isNot(contains(orchestratorMarker)));
    },
  );

  test(
    'one generateReply call does not concatenate condition memory and orchestrator replies',
    () async {
      const conditionMarker = 'CONDITION_MEMORY_ONLY_MARKER';
      const orchestratorMarker = 'ORCHESTRATOR_ONLY_MARKER';
      final orchestrator = _FakeConversationOrchestrator(
        _orchestratorResponse(
          route: ConversationRoute.localCasual,
          replyText: orchestratorMarker,
        ),
      );
      final controller = ChatPanelConversationController(
        conversationOrchestrator: orchestrator,
      );

      final response = await controller.generateReply(
        ChatPanelConversationRequest(
          plantId: 'plant-1',
          plantName: '초록이',
          userMessage: '괜찮아?',
          waterDay: 0,
          latestConditionMemory: LatestConditionMemory(
            message: conditionMarker,
            eventType: 'uncertain',
          ),
          fetchDialogueReply: _nullDialogueReply,
        ),
      );

      expect(orchestrator.callCount, 0);
      expect(response.replyText, contains(conditionMarker));
      expect(response.replyText, isNot(contains(orchestratorMarker)));
      expect(response.conditionMemoryReplyCount, 1);
    },
  );

  test('does not import forbidden UI or integration code', () {
    final source = File(
      'lib/dialogue/chat_panel_conversation_controller.dart',
    ).readAsStringSync().toLowerCase();

    const forbiddenSnippets = [
      'package:flutter/',
      'chat_panel.dart',
      'widgets',
      'main.dart',
      'supabase',
      'gemini',
      'kindwise',
      'crawler',
      'edge function',
      'edge_function',
      'payment',
      'entitlement',
      'plant_memories',
      'dailykeywordcontext',
      'daily_keyword_context',
    ];

    for (final snippet in forbiddenSnippets) {
      expect(
        source,
        isNot(contains(snippet)),
        reason: 'controller must not reference $snippet',
      );
    }
  });
}

Future<String?> _nullDialogueReply({String? situation, String? conditionKey}) {
  return Future<String?>.value();
}

ConversationResponse _orchestratorResponse({
  required ConversationRoute route,
  required String replyText,
  bool usedApi = false,
  bool isFallback = false,
}) {
  return ConversationResponse(
    replyText: replyText,
    route: route,
    usedApi: usedApi,
    isFallback: isFallback,
  );
}

class _FakeConversationOrchestrator extends ConversationOrchestrator {
  _FakeConversationOrchestrator(this.response);

  final ConversationResponse response;
  final List<ConversationRequest> requests = [];

  int get callCount => requests.length;

  @override
  Future<ConversationResponse> respond(ConversationRequest request) async {
    requests.add(request);
    return response;
  }
}

class _ReplyRequest {
  const _ReplyRequest({required this.situation, required this.conditionKey});

  final String? situation;
  final String? conditionKey;
}
