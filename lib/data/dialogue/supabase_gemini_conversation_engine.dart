import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dialogue/engines/api_conversation_engine.dart';
import '../../dialogue/models/conversation_request.dart';
import '../../dialogue/models/conversation_response.dart';
import '../../dialogue/models/conversation_route.dart';

typedef PlantChatFunctionInvoker =
    Future<Object?> Function(Map<String, Object?> body);

class SupabaseGeminiConversationEngine implements ApiConversationEngine {
  SupabaseGeminiConversationEngine({
    required this.invoke,
    Duration timeout = const Duration(seconds: 9),
  }) : timeout = _validatedTimeout(timeout);

  factory SupabaseGeminiConversationEngine.fromClient(
    SupabaseClient client, {
    Duration timeout = const Duration(seconds: 9),
  }) {
    return SupabaseGeminiConversationEngine(
      timeout: timeout,
      invoke: (body) async {
        final response = await client.functions.invoke(
          functionName,
          body: body,
        );
        return response.data;
      },
    );
  }

  static const functionName = 'plant-chat';
  static const maximumMessageLength = 500;
  static const maximumReplyLength = 500;

  final PlantChatFunctionInvoker invoke;
  final Duration timeout;

  @override
  Future<ConversationResponse> generate(ConversationRequest request) async {
    final message = _requiredBounded(
      request.userMessage,
      'userMessage',
      maximumMessageLength,
    );
    final plantName = _requiredBounded(
      request.plantName,
      'plantName',
      40,
    );

    final body = <String, Object?>{
      'message': message,
      'plantName': plantName,
      if (_optionalBounded(request.species, 'species', 80) case final species?)
        'species': species,
      if (_optionalBounded(request.mood, 'mood', 40) case final mood?)
        'mood': mood,
      if (request.friendship case final friendship?)
        'friendship': friendship.clamp(0, 100),
      'locale': _normalizedLocale(request.locale),
    };

    final rawResponse = await invoke(body).timeout(timeout);
    if (rawResponse is! Map) {
      throw const FormatException(
        'Plant chat function returned an invalid response.',
      );
    }

    final response = rawResponse.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final reply = _requiredBounded(
      response['reply'],
      'reply',
      maximumReplyLength,
    );

    return ConversationResponse(
      replyText: reply,
      route: ConversationRoute.api,
      usedApi: true,
      debugReason: 'gemini_api',
    );
  }

  static String _requiredBounded(
    Object? value,
    String field,
    int maximumLength,
  ) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$field is required.');
    }

    final normalized = value.trim();
    if (normalized.runes.length > maximumLength) {
      throw FormatException('$field exceeded its length limit.');
    }
    return normalized;
  }

  static String? _optionalBounded(
    String? value,
    String field,
    int maximumLength,
  ) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.runes.length > maximumLength) {
      throw FormatException('$field exceeded its length limit.');
    }
    return normalized;
  }

  static String _normalizedLocale(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.runes.length > 16) {
      return 'ko-KR';
    }
    return normalized;
  }

  static Duration _validatedTimeout(Duration value) {
    if (value <= Duration.zero) {
      throw ArgumentError.value(value, 'timeout', 'must be positive');
    }
    return value;
  }
}
