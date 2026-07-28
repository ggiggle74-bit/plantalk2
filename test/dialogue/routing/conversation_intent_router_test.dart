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

  final qualityCases = <String, ConversationRoute>{
    '무가리야': ConversationRoute.localCasual,
    '무가리야 오늘 어때?': ConversationRoute.localCasual,
    '안녕, 오늘 기분은 어때?': ConversationRoute.localCasual,
    '무가리야 공룡은 왜 멸종했어?': ConversationRoute.api,
    '안녕, 공룡은 왜 멸종했어?': ConversationRoute.api,
    '무가리야 우주의 크기를 설명해줘': ConversationRoute.api,
    '무가리야 나 오늘 학교에서 속상한 일이 있었어': ConversationRoute.api,
    'Why did dinosaurs disappear?': ConversationRoute.api,
  };

  for (final entry in qualityCases.entries) {
    test('quality gate routes "${entry.key}" to ${entry.value.name}', () {
      final route = router.route(
        ConversationRequest(
          plantId: 'plant-1',
          plantName: '무가리',
          userMessage: entry.key,
        ),
      );

      expect(route, entry.value);
    });
  }

  test('uses the request plant name instead of a fixed character name', () {
    final cases = <({String plantName, String message, ConversationRoute route})>[
      (
        plantName: '초록이',
        message: '초록아 오늘 어때?',
        route: ConversationRoute.localCasual,
      ),
      (
        plantName: '초록이',
        message: '초록아 공룡은 왜 멸종했어?',
        route: ConversationRoute.api,
      ),
      (
        plantName: '해피',
        message: '해피야 오늘 어때?',
        route: ConversationRoute.localCasual,
      ),
      (
        plantName: '해피',
        message: '해피야 우주의 크기를 알려줘',
        route: ConversationRoute.api,
      ),
    ];

    for (final testCase in cases) {
      expect(
        router.route(
          ConversationRequest(
            plantId: 'plant-1',
            plantName: testCase.plantName,
            userMessage: testCase.message,
          ),
        ),
        testCase.route,
        reason: '${testCase.plantName}: ${testCase.message}',
      );
    }
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

  test('routes a past-tense recent condition question to memory', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '최근 상태가 어땠어?',
        latestConditionMemory: LatestConditionMemory(
          message: '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.',
          eventType: 'normal',
        ),
      ),
    );

    expect(route, ConversationRoute.conditionMemory);
  });

  test('routes an explicit condition-history question locally without memory', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '최근 사진에서 상태가 어땠어?',
      ),
    );

    expect(route, ConversationRoute.conditionMemory);
  });

  test('keeps a general plant-care explanation on the API route', () {
    final route = router.route(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '몬스테라 잎이 처지는 일반적인 원인을 설명해줘',
      ),
    );

    expect(route, ConversationRoute.api);
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
