import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel.dart';
import 'package:plantalk2/dialogue/chat_panel_conversation_controller.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_opening_context.dart';
import 'package:plantalk2/dialogue/engines/local_casual_conversation_engine.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 9);

  test('local casual engine consumes an opening keyword exactly once', () {
    const engine = LocalCasualConversationEngine();
    final openingContext = _openingContext();

    final first = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '뭐해?',
        now: now,
        dailyOpeningContext: openingContext,
        isOpeningTurn: true,
      ),
    );
    final second = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        now: now.add(const Duration(minutes: 1)),
        dailyOpeningContext: openingContext,
        isOpeningTurn: false,
      ),
    );

    expect(first.usedDailyKeyword, isTrue);
    expect(first.replyText, contains('장맛비'));
    expect(openingContext.isConsumed, isTrue);
    expect(openingContext.consumedAt, now);
    expect(second.usedDailyKeyword, isFalse);
    expect(second.replyText, isNot(contains('장맛비')));
  });

  test('non-opening local request does not consume the opening context', () {
    const engine = LocalCasualConversationEngine();
    final openingContext = _openingContext();

    final response = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        now: now,
        dailyOpeningContext: openingContext,
        isOpeningTurn: false,
      ),
    );

    expect(response.usedDailyKeyword, isFalse);
    expect(openingContext.isConsumed, isFalse);
  });

  test('DB reply wins without consuming the opening context', () async {
    final openingContext = _openingContext();
    final controller = ChatPanelConversationController();

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        now: now,
        dailyOpeningContext: openingContext,
        isOpeningTurn: true,
        fetchDialogueReply: ({situation, conditionKey}) async => 'DB_ONLY_MARKER',
      ),
    );

    expect(response.replyText, contains('DB_ONLY_MARKER'));
    expect(response.replyText, isNot(contains('장맛비')));
    expect(openingContext.isConsumed, isFalse);
  });

  test('condition-memory reply wins without consuming opening context', () async {
    final openingContext = _openingContext();
    final controller = ChatPanelConversationController();

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '상태 어때?',
        waterDay: 0,
        now: now,
        dailyOpeningContext: openingContext,
        isOpeningTurn: true,
        latestConditionMemory: const LatestConditionMemory(
          message: '사진만으로는 상태를 확실히 판단하기 어려워요.',
          eventType: 'uncertain',
        ),
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(response.replyText, contains('사진만으로는'));
    expect(response.replyText, isNot(contains('장맛비')));
    expect(openingContext.isConsumed, isFalse);
  });

  test('API-like message does not consume opening context', () async {
    final openingContext = _openingContext();
    final controller = ChatPanelConversationController();

    final response = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '몬스테라 분갈이 방법과 흙 배합을 자세히 설명해줘',
        waterDay: 0,
        now: now,
        dailyOpeningContext: openingContext,
        isOpeningTurn: true,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(response.replyText, isNot(contains('장맛비')));
    expect(openingContext.isConsumed, isFalse);
  });

  test('controller uses opening keyword only on the first local turn', () async {
    final openingContext = _openingContext();
    final controller = ChatPanelConversationController();

    final first = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        now: now,
        dailyOpeningContext: openingContext,
        isOpeningTurn: true,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );
    final second = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        waterDay: 0,
        now: now.add(const Duration(minutes: 1)),
        dailyOpeningContext: openingContext,
        isOpeningTurn: false,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(first.replyText, contains('장맛비'));
    expect(second.replyText, isNot(contains('장맛비')));
    expect(openingContext.isConsumed, isTrue);
  });

  testWidgets('ChatPanel marks only the first user message as opening', (
    tester,
  ) async {
    final openingContext = _openingContext();
    final controller = _RecordingConversationController();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPanel(
          plantName: '무가리',
          initialPlantMessage: '',
          waterDay: 0,
          conversationController: controller,
          dailyOpeningContext: openingContext,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '안녕');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '또 왔어');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(controller.requests, hasLength(2));
    expect(controller.requests.first.isOpeningTurn, isTrue);
    expect(controller.requests.last.isOpeningTurn, isFalse);
    expect(controller.requests.first.dailyOpeningContext, same(openingContext));
    expect(controller.requests.last.dailyOpeningContext, same(openingContext));
  });
}

Future<String?> _nullDialogueReply({String? situation, String? conditionKey}) {
  return Future<String?>.value();
}

DailyOpeningContext _openingContext() {
  return DailyOpeningContext(
    selectedCandidate: const DailyKeywordEntry(
      type: 'weather',
      keyword: '장맛비',
      hint: '비가 이어지는 날',
      plantHint: '실내 공기 흐름을 살피기',
      tone: 'gentle',
      fitScore: 0.82,
    ),
  );
}

class _RecordingConversationController extends ChatPanelConversationController {
  final List<ChatPanelConversationRequest> requests = [];

  @override
  Future<ChatPanelConversationResponse> generateReply(
    ChatPanelConversationRequest request,
  ) async {
    requests.add(request);
    return ChatPanelConversationResponse(
      replyText: 'reply-${requests.length}',
      conditionMemoryReplyCount: request.conditionMemoryReplyCount,
    );
  }
}
