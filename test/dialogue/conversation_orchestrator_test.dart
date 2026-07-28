import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/conversation_orchestrator.dart';
import 'package:plantalk2/dialogue/engines/api_conversation_engine.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_response.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';
import 'package:plantalk2/dialogue/routing/conversation_intent_router.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  test('uses local casual engine for casual route', () async {
    const orchestrator = ConversationOrchestrator();

    final response = await orchestrator.respond(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
      ),
    );

    expect(response.route, ConversationRoute.localCasual);
    expect(response.isFallback, isFalse);
    expect(response.usedApi, isFalse);
  });

  test('uses condition memory engine for condition route', () async {
    const orchestrator = ConversationOrchestrator();

    final response = await orchestrator.respond(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '상태 어때?',
        latestConditionMemory: LatestConditionMemory(
          message: '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.',
          eventType: 'normal',
        ),
      ),
    );

    expect(response.route, ConversationRoute.conditionMemory);
    expect(response.usedConditionMemory, isTrue);
    expect(response.isFallback, isFalse);
  });

  test('falls back when API route is selected without API engine', () async {
    const orchestrator = ConversationOrchestrator();

    final response = await orchestrator.respond(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '몬스테라 분갈이 방법과 흙 배합을 자세히 설명해줘',
      ),
    );

    expect(response.route, ConversationRoute.api);
    expect(response.isFallback, isTrue);
    expect(response.usedApi, isFalse);
    expect(response.debugReason, 'api_engine_unavailable');
  });

  test('uses the API engine for unrecognized conversation', () async {
    final apiEngine = _RecordingApiConversationEngine(
      const ConversationResponse(
        replyText: '영화 이야기도 듣고 싶어.',
        route: ConversationRoute.api,
        usedApi: true,
      ),
    );
    final orchestrator = ConversationOrchestrator(
      apiConversationEngine: apiEngine,
    );

    final response = await orchestrator.respond(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '어제 오래된 영화를 다시 봤어',
      ),
    );

    expect(apiEngine.requests, hasLength(1));
    expect(response.replyText, '영화 이야기도 듣고 싶어.');
    expect(response.route, ConversationRoute.api);
    expect(response.usedApi, isTrue);
    expect(response.isFallback, isFalse);
  });

  test('fails closed when the API engine throws', () async {
    final orchestrator = ConversationOrchestrator(
      apiConversationEngine: _ThrowingApiConversationEngine(),
    );

    final response = await orchestrator.respond(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '몬스테라 분갈이 방법을 자세히 알려줘',
      ),
    );

    expect(response.route, ConversationRoute.api);
    expect(response.usedApi, isFalse);
    expect(response.isFallback, isTrue);
    expect(response.debugReason, 'api_request_failed');
  });

  test('respondForRoute does not ask the router to decide again', () async {
    const orchestrator = ConversationOrchestrator(
      router: _ThrowingConversationIntentRouter(),
    );
    const request = ConversationRequest(
      plantId: 'plant-1',
      plantName: '무가리',
      userMessage: '안녕',
    );

    final response = await orchestrator.respondForRoute(
      request,
      ConversationRoute.localCasual,
    );

    expect(response.route, ConversationRoute.localCasual);
    expect(response.isFallback, isFalse);
  });

  test('new dialogue boundary code does not import forbidden integrations', () {
    final files = Directory('lib/dialogue')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final path = file.path.replaceAll('\\', '/');
          return path.endsWith('lib/dialogue/conversation_orchestrator.dart') ||
              path.contains('/models/conversation_') ||
              path.contains('/models/daily_keyword_context.dart') ||
              path.contains('/models/user_region_context.dart') ||
              path.contains('/routing/conversation_intent_router.dart') ||
              path.contains('/engines/') ||
              path.contains('/tone/mugari_tone_composer.dart');
        })
        .toList();

    expect(files, isNotEmpty);

    const forbiddenSnippets = [
      'supabase',
      'package:flutter/',
      'widgets',
      'chat_panel',
      'main.dart',
      'gemini',
      'kindwise',
      'crawler',
      'edge function',
      'edge_function',
      'plant_analysis',
    ];

    for (final file in files) {
      final contents = file.readAsStringSync().toLowerCase();
      for (final snippet in forbiddenSnippets) {
        expect(
          contents,
          isNot(contains(snippet)),
          reason: '${file.path} must not reference $snippet',
        );
      }
    }
  });
}


class _ThrowingConversationIntentRouter extends ConversationIntentRouter {
  const _ThrowingConversationIntentRouter();

  @override
  ConversationRoute route(ConversationRequest request) {
    throw StateError('router must not be called');
  }
}

class _RecordingApiConversationEngine implements ApiConversationEngine {
  _RecordingApiConversationEngine(this.response);

  final ConversationResponse response;
  final List<ConversationRequest> requests = [];

  @override
  Future<ConversationResponse> generate(ConversationRequest request) async {
    requests.add(request);
    return response;
  }
}

class _ThrowingApiConversationEngine implements ApiConversationEngine {
  @override
  Future<ConversationResponse> generate(ConversationRequest request) {
    throw StateError('provider unavailable');
  }
}
