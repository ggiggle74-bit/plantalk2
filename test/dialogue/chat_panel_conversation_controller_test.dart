import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel_conversation_controller.dart';
import 'package:plantalk2/dialogue/dialogue_engine.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  test(
    'returns DB-authored reply when fetchDialogueReply returns a reply',
    () async {
      final controller = ChatPanelConversationController();
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
      expect(response.replyText, contains('DB가 고른 인사야.'));
      expect(response.conditionMemoryReplyCount, 0);
    },
  );

  test(
    'falls back to condition-memory reply when DB reply is unavailable',
    () async {
      final controller = ChatPanelConversationController();

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

      expect(response.replyText, contains('사진만으로는 상태를 확실히 판단하기 어려워요.'));
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
    'uses local placeholder fallback when DB and condition fallback are absent',
    () async {
      final controller = ChatPanelConversationController();

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
      expect(response.conditionMemoryReplyCount, 0);
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

class _ReplyRequest {
  const _ReplyRequest({required this.situation, required this.conditionKey});

  final String? situation;
  final String? conditionKey;
}
