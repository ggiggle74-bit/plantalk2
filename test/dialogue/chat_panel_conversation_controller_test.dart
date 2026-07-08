import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel_conversation_controller.dart';
import 'package:plantalk2/dialogue/conversation_orchestrator.dart';
import 'package:plantalk2/dialogue/dialogue_engine.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_response.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  test(
    'returns DB-authored reply when fetchDialogueReply returns a reply',
    () async {
      final orchestrator = _FakeConversationOrchestrator(
        _orchestratorResponse(
          route: ConversationRoute.localCasual,
          replyText: '오케스트레이터 인사야.',
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
            return 'DB가 고른 인사야.';
          },
        ),
      );

      expect(requests, hasLength(1));
      expect(requests.single.situation, 'greeting');
      expect(orchestrator.callCount, 0);
      expect(response.replyText, contains('DB가 고른 인사야.'));
      expect(response.replyText, isNot(contains('오케스트레이터 인사야.')));
      expect(response.conditionMemoryReplyCount, 0);
    },
  );

  test(
    'falls back to condition-memory reply when DB reply is unavailable',
    () async {
      final orchestrator = _FakeConversationOrchestrator(
        _orchestratorResponse(
          route: ConversationRoute.localCasual,
          replyText: '오케스트레이터 인사야.',
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
            message: '사진만으로는 상태를 확실히 판단하기 어려워요.',
            eventType: 'uncertain',
          ),
          fetchDialogueReply: _nullDialogueReply,
        ),
      );

      expect(orchestrator.callCount, 0);
      expect(response.replyText, contains('사진만으로는 상태를 확실히 판단하기 어려워요.'));
      expect(response.replyText, isNot(contains('오케스트레이터 인사야.')));
      expect(response.conditionMemoryReplyCount, 1);
    },
  );

  test('applies legacy personality after selecting the reply', () async {
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

    expect(
      response.replyText,
      DialogueEngine.applyPlantPersonality(
        reply: baseReply,
        plantId: 'plant-tone',
        plantName: '무가리',
      ),
    );
  });

  test(
    'uses local casual orchestrator reply when DB reply is unavailable',
    () async {
      final orchestrator = _FakeConversationOrchestrator(
        _orchestratorResponse(
          route: ConversationRoute.localCasual,
          replyText: '오케스트레이터가 고른 짧은 인사야.',
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
      expect(response.replyText, contains('오케스트레이터가 고른 짧은 인사야.'));
      expect(response.conditionMemoryReplyCount, 0);
    },
  );

  test(
    'uses local placeholder fallback when DB and condition fallback are absent',
    () async {
      final orchestrator = _FakeConversationOrchestrator(
        _orchestratorResponse(
          route: ConversationRoute.fallback,
          replyText: '오케스트레이터 fallback은 쓰면 안 돼.',
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
          userMessage: '너 누구야?',
          waterDay: 0,
          fetchDialogueReply: _nullDialogueReply,
        ),
      );

      expect(response.replyText, contains('나는 무가리야.'));
      expect(response.replyText, isNot(contains('오케스트레이터 fallback은 쓰면 안 돼.')));
      expect(response.conditionMemoryReplyCount, 0);
    },
  );

  test(
    'API-like message does not replace legacy fallback in selective wiring',
    () async {
      final orchestrator = _FakeConversationOrchestrator(
        _orchestratorResponse(
          route: ConversationRoute.api,
          replyText: 'API 경계 답변은 아직 쓰면 안 돼.',
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
          waterDay: 0,
          fetchDialogueReply: _nullDialogueReply,
        ),
      );

      expect(orchestrator.callCount, 0);
      expect(response.replyText, isNot(contains('API 경계 답변은 아직 쓰면 안 돼.')));
      expect(response.conditionMemoryReplyCount, 0);
    },
  );

  test('one generateReply call returns one final reply path', () async {
    final orchestrator = _FakeConversationOrchestrator(
      _orchestratorResponse(
        route: ConversationRoute.localCasual,
        replyText: '오케스트레이터 한 줄',
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
        waterDay: 2,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(orchestrator.callCount, 1);
    expect(response.replyText, contains('오케스트레이터 한 줄'));
    expect(response.replyText, isNot(contains('목 마르다')));
    expect(response.replyText, isNot(contains('이틀째다')));
    expect(response.replyText, isNot(contains('물 달라고')));
    expect(response.replyText, isNot(contains('오늘은 대화도')));
  });

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
  bool isFallback = false,
}) {
  return ConversationResponse(
    replyText: replyText,
    route: route,
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
