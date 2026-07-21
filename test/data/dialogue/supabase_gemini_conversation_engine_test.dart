import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/data/dialogue/supabase_gemini_conversation_engine.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';

void main() {
  test('maps bounded plant context and returns an API response', () async {
    Map<String, Object?>? receivedBody;
    final engine = SupabaseGeminiConversationEngine(
      invoke: (body) async {
        receivedBody = body;
        return {'reply': '잎을 흔들며 네 이야기 듣고 있었어.'};
      },
    );

    final response = await engine.generate(
      const ConversationRequest(
        plantId: 'private-plant-id',
        plantName: '무가리',
        userMessage: '우주에는 별이 몇 개야?',
        species: '몬스테라',
        mood: 'calm',
        friendship: 140,
        locale: 'ko-KR',
      ),
    );

    expect(receivedBody, {
      'message': '우주에는 별이 몇 개야?',
      'plantName': '무가리',
      'species': '몬스테라',
      'mood': 'calm',
      'friendship': 100,
      'locale': 'ko-KR',
    });
    expect(receivedBody, isNot(containsPair('plantId', anything)));
    expect(response.replyText, '잎을 흔들며 네 이야기 듣고 있었어.');
    expect(response.route, ConversationRoute.api);
    expect(response.usedApi, isTrue);
    expect(response.isFallback, isFalse);
    expect(response.debugReason, 'gemini_api');
  });

  test('omits empty optional context', () async {
    Map<String, Object?>? receivedBody;
    final engine = SupabaseGeminiConversationEngine(
      invoke: (body) async {
        receivedBody = body;
        return {'reply': '응, 듣고 있어.'};
      },
    );

    await engine.generate(
      const ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '내 얘기 듣고 있어?',
        species: ' ',
        mood: '',
      ),
    );

    expect(receivedBody, isNot(containsPair('species', anything)));
    expect(receivedBody, isNot(containsPair('mood', anything)));
    expect(receivedBody, isNot(containsPair('friendship', anything)));
  });

  test('rejects invalid function responses', () {
    final engine = SupabaseGeminiConversationEngine(
      invoke: (_) async => {'reply': ' '},
    );

    expect(
      engine.generate(_request()),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects oversized user input before invoking the function', () {
    var callCount = 0;
    final engine = SupabaseGeminiConversationEngine(
      invoke: (_) async {
        callCount++;
        return {'reply': 'unused'};
      },
    );

    expect(
      engine.generate(_request(message: List.filled(501, '가').join())),
      throwsA(isA<FormatException>()),
    );
    expect(callCount, 0);
  });

  test('times out a stalled function invocation', () {
    final completer = Completer<Object?>();
    final engine = SupabaseGeminiConversationEngine(
      timeout: const Duration(milliseconds: 1),
      invoke: (_) => completer.future,
    );

    expect(
      engine.generate(_request()),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('requires a positive timeout', () {
    expect(
      () => SupabaseGeminiConversationEngine(
        timeout: Duration.zero,
        invoke: (_) async => {'reply': 'unused'},
      ),
      throwsArgumentError,
    );
  });
}

ConversationRequest _request({String message = '알려줘'}) {
  return ConversationRequest(
    plantId: 'plant-1',
    plantName: '무가리',
    userMessage: message,
  );
}
