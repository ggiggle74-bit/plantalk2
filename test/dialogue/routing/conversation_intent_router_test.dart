import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';
import 'package:plantalk2/dialogue/routing/conversation_intent_router.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  const router = ConversationIntentRouter();

  test('routes greeting and casual messages to local casual', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
      ),
    );

    expect(route, ConversationRoute.localCasual);
  });

  test('routes condition follow-up to condition memory when memory exists', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '괜찮아?',
        latestConditionMemory: LatestConditionMemory(
          message: '사진을 보니 물이 조금 필요해 보여요.',
          eventType: 'needs_water',
        ),
      ),
    );

    expect(route, ConversationRoute.conditionMemory);
  });

  test('routes unrecognized nonempty conversation to api', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '어제 오래된 영화를 다시 봤어',
      ),
    );

    expect(route, ConversationRoute.api);
  });

  test('keeps empty input on the local fallback route', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '   ',
      ),
    );

    expect(route, ConversationRoute.fallback);
  });

  test('routes long or knowledge-like questions to api', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '몬스테라 분갈이 방법과 흙 배합을 자세히 설명해줘',
      ),
    );

    expect(route, ConversationRoute.api);
  });
}
