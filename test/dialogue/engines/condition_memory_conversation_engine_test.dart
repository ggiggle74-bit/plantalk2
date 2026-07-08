import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/engines/condition_memory_conversation_engine.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  test('replies from latest condition memory without API', () {
    const engine = ConditionMemoryConversationEngine();
    final response = engine.generate(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '물 줘?',
        latestConditionMemory: LatestConditionMemory(
          message: '사진을 보니 물이 조금 필요해 보여요.',
          eventType: 'needs_water',
        ),
      ),
    );

    expect(response, isNotNull);
    expect(response!.route, ConversationRoute.conditionMemory);
    expect(response.usedConditionMemory, isTrue);
    expect(response.usedApi, isFalse);
    expect(response.replyText, contains('물이 조금'));
    expect(response.replyText, contains('흙'));
  });
}
