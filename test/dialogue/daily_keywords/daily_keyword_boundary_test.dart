import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'daily keyword layer does not reference restricted integrations or memory',
    () {
      final files = Directory(
        'lib/dialogue/daily_keywords',
      ).listSync(recursive: true).whereType<File>().toList();

      expect(files, isNotEmpty);

      const forbiddenSnippets = [
        'plant_memories',
        'plantid',
        'plant_id',
        'latestconditionmemory',
        'supabase',
        'gemini',
        'kindwise',
        'conversationrequest',
        'conversationresponse',
        'conversationorchestrator',
        'chatpanelconversationcontroller',
        'dialogueengine',
        'dialogueservice',
        'apiconversationengine',
        'userregioncontext',
      ];

      for (final file in files) {
        final source = file.readAsStringSync().toLowerCase();
        for (final snippet in forbiddenSnippets) {
          expect(
            source,
            isNot(contains(snippet)),
            reason: '${file.path} must not reference $snippet',
          );
        }
      }
    },
  );

  test(
    'runtime conversation files do not reference LocalDailyKeywordSource',
    () {
      const files = [
        'lib/dialogue/chat_panel_conversation_controller.dart',
        'lib/dialogue/conversation_orchestrator.dart',
        'lib/dialogue/models/conversation_request.dart',
        'lib/main.dart',
      ];

      for (final path in files) {
        final source = File(path).readAsStringSync().toLowerCase();
        expect(source, isNot(contains('localdailykeywordsource')));
        expect(source, isNot(contains('local_daily_keyword_source')));
        for (final snippet in [
          'dailykeywordsource',
          'dailykeywordsourcerequest',
          'localdailykeywordsourceadapter',
          'fallbackdailykeywordsource',
          'local_daily_keyword_source_adapter',
          'fallback_daily_keyword_source',
          'daily_keyword_source.dart',
        ]) {
          expect(source, isNot(contains(snippet)));
        }
      }
    },
  );

  test('safe issue catalog stays outside source and runtime wiring', () {
    const files = [
      'lib/dialogue/daily_keywords/local_daily_keyword_source.dart',
      'lib/dialogue/chat_panel_conversation_controller.dart',
      'lib/dialogue/conversation_orchestrator.dart',
      'lib/dialogue/models/conversation_request.dart',
      'lib/main.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync().toLowerCase();
      expect(source, isNot(contains('safeissuekeywordcatalog')));
      expect(source, isNot(contains('safe_issue_keyword_catalog')));
    }
  });

  test('opening projection stays outside conversation runtime wiring', () {
    const files = [
      'lib/dialogue/engines/local_casual_conversation_engine.dart',
      'lib/dialogue/chat_panel_conversation_controller.dart',
      'lib/dialogue/conversation_orchestrator.dart',
      'lib/dialogue/models/conversation_request.dart',
      'lib/main.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync().toLowerCase();
      for (final snippet in [
        'dailyopeningkeywordselector',
        'daily_opening_keyword_selector',
        'dailyopeningcontext',
        'daily_opening_context',
      ]) {
        expect(source, isNot(contains(snippet)));
      }
    }
  });
}
