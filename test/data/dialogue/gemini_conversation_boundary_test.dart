import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gemini integration stays outside the dialogue policy layer', () {
    final files = Directory(
      'lib/dialogue',
    ).listSync(recursive: true).whereType<File>();

    for (final file in files) {
      final source = file.readAsStringSync().toLowerCase();
      expect(
        source,
        isNot(contains('supabasegeminiconversationengine')),
        reason: '${file.path} must depend only on ApiConversationEngine',
      );
      expect(
        source,
        isNot(contains('supabase_gemini_conversation_engine')),
        reason: '${file.path} must not import the Supabase adapter',
      );
      expect(
        source,
        isNot(contains('generativelanguage.googleapis.com')),
        reason: '${file.path} must not know the Gemini endpoint',
      );
    }
  });

  test('the app adapter invokes only the fixed Supabase function', () {
    final source = File(
      'lib/data/dialogue/supabase_gemini_conversation_engine.dart',
    ).readAsStringSync();

    expect(source, contains("functionName = 'plant-chat'"));
    expect(source, contains('client.functions.invoke'));
    expect(source, isNot(contains('GEMINI_API_KEY')));
    expect(source, isNot(contains('generativelanguage.googleapis.com')));
    expect(source, isNot(contains('plant_memories')));
  });

  test('main delegates remote chat composition to one app factory', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('PlantChatConversationControllerFactory.supabase()'),
    );
    expect(
      source,
      contains('conversationController: chatConversationController'),
    );
    expect(source, isNot(contains('SupabaseGeminiConversationEngine')));
    expect(source, isNot(contains('GEMINI_API_KEY')));
    expect(source, isNot(contains('plant-chat')));
  });

  test('Gemini secret is read only by the Edge Function entrypoint', () {
    final entrypoint = File(
      'supabase/functions/plant-chat/index.ts',
    ).readAsStringSync();
    final handler = File(
      'supabase/functions/plant-chat/handler.ts',
    ).readAsStringSync();

    expect(entrypoint, contains("Deno.env.get('GEMINI_API_KEY')"));
    expect(handler, isNot(contains("Deno.env.get('GEMINI_API_KEY')")));
    expect(handler, contains('gemini-3.1-flash-lite'));
    expect(handler, contains('maximumRequestsPerMinute ?? 12'));
    expect(handler, contains('maxOutputTokens: 180'));
    expect(handler, isNot(contains('console.log')));
    expect(handler, isNot(contains('plant_memories')));
  });
}
