import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel_conversation_controller.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_conversation_material_context.dart';
import 'package:plantalk2/dialogue/models/conversation_usage_ledger.dart';

void main() {
  final materialContext = DailyConversationMaterialContext(
    date: DateTime.utc(2026, 7, 28),
    locale: 'ko-KR',
    materials: [
      DailyConversationMaterial(
        type: 'weather',
        keyword: '비',
        hint: '비가 내리는 날',
        plantHint: '창가의 빗소리를 함께 듣기',
        tone: 'gentle',
        fitScore: 0.82,
      ),
      DailyConversationMaterial(
        type: 'safe_issue',
        keyword: '독서',
        hint: '책 이야기를 나누는 날',
        plantHint: '조용한 시간을 함께 보내기',
        tone: 'calm',
        fitScore: 0.72,
      ),
    ],
  );

  test('controller carries session material into the local engine', () async {
    final controller = ChatPanelConversationController();
    final ledger = ConversationUsageLedger();

    final first = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '오늘 뭐해?',
        waterDay: 0,
        dailyConversationMaterialContext: materialContext,
        usageLedger: ledger,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );
    final second = await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '오늘 뭐해?',
        waterDay: 0,
        dailyConversationMaterialContext: materialContext,
        usageLedger: ledger,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(first.replyText, isNot(second.replyText));
    expect(ledger.turn, 2);
    expect(ledger.trackedMaterialKeys, hasLength(2));
  });

  test('API-routed conversation does not consume local material', () async {
    final controller = ChatPanelConversationController();
    final ledger = ConversationUsageLedger();

    await controller.generateReply(
      ChatPanelConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '공룡은 왜 멸종했어?',
        waterDay: 0,
        dailyConversationMaterialContext: materialContext,
        usageLedger: ledger,
        fetchDialogueReply: _nullDialogueReply,
      ),
    );

    expect(ledger.turn, 0);
    expect(ledger.trackedMaterialKeys, isEmpty);
    expect(ledger.trackedReplyKeys, isEmpty);
  });
}

Future<String?> _nullDialogueReply({
  String? situation,
  String? conditionKey,
}) {
  return Future<String?>.value();
}
