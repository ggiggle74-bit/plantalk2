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
    'runtime conversation files do not reference DailyKeywordSource',
    () {
      const files = [
        'lib/dialogue/chat_panel.dart',
        'lib/dialogue/chat_panel_conversation_controller.dart',
        'lib/dialogue/conversation_orchestrator.dart',
        'lib/dialogue/engines/local_casual_conversation_engine.dart',
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
          'dailyconversationmaterialprovider',
          'daily_conversation_material_provider',
          'dailyconversationmaterialprojector',
          'daily_conversation_material_projector',
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

  test('opening context is carried only by composition root and local chat', () {
    const wiredFiles = [
      'lib/main.dart',
      'lib/dialogue/chat_panel.dart',
      'lib/dialogue/chat_panel_conversation_controller.dart',
      'lib/dialogue/engines/local_casual_conversation_engine.dart',
      'lib/dialogue/models/conversation_request.dart',
    ];

    for (final path in wiredFiles) {
      final source = File(path).readAsStringSync().toLowerCase();
      expect(
        source,
        contains('dailyopeningcontext'),
        reason: '$path must carry the opening context',
      );
    }

    final orchestrator = File(
      'lib/dialogue/conversation_orchestrator.dart',
    ).readAsStringSync().toLowerCase();
    expect(orchestrator, isNot(contains('dailyopeningcontext')));
    expect(orchestrator, isNot(contains('daily_opening_context')));
  });

  test('session material is carried without source or projector wiring', () {
    const wiredFiles = [
      'lib/main.dart',
      'lib/dialogue/chat_panel.dart',
      'lib/dialogue/chat_panel_conversation_controller.dart',
      'lib/dialogue/engines/local_casual_conversation_engine.dart',
      'lib/dialogue/models/conversation_request.dart',
    ];

    for (final path in wiredFiles) {
      final source = File(path).readAsStringSync().toLowerCase();
      expect(
        source,
        contains('dailyconversationmaterialcontext'),
        reason: '$path must carry the session material context',
      );
    }

    final orchestrator = File(
      'lib/dialogue/conversation_orchestrator.dart',
    ).readAsStringSync().toLowerCase();
    expect(orchestrator, isNot(contains('dailyconversationmaterialcontext')));
    expect(
      orchestrator,
      isNot(contains('daily_conversation_material_context')),
    );
  });

  test('opening context provider and factory stay outside runtime wiring', () {
    const files = [
      'lib/dialogue/chat_panel.dart',
      'lib/dialogue/chat_panel_conversation_controller.dart',
      'lib/dialogue/conversation_orchestrator.dart',
      'lib/dialogue/engines/local_casual_conversation_engine.dart',
      'lib/dialogue/models/conversation_request.dart',
      'lib/main.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync().toLowerCase();
      for (final snippet in [
        'dailyopeningcontextprovider',
        'daily_opening_context_provider',
        'dailyopeningcontextproviderfactory',
        'daily_opening_context_provider_factory',
      ]) {
        expect(source, isNot(contains(snippet)));
      }
    }
  });

  test('Supabase adapter stays outside dialogue and memory boundaries', () {
    final source = File(
      'lib/data/daily_keywords/supabase_daily_keyword_source.dart',
    ).readAsStringSync().toLowerCase();

    expect(source, contains('supabase'));
    expect(source, contains('daily_keyword_contexts'));
    for (final snippet in [
      'plant_memories',
      'conversationrequest',
      'conversationorchestrator',
      'chatpanelconversationcontroller',
      'apiconversationengine',
    ]) {
      expect(source, isNot(contains(snippet)));
    }
  });

  test('main delegates remote source composition to the coordinator', () {
    final source = File('lib/main.dart').readAsStringSync().toLowerCase();

    expect(source, contains('dailyopeningcontextcoordinator.supabase()'));
    expect(source, contains('loadsessionforchat'));
    expect(source, contains('dailyopeningcontext: dailychatcontext'));
    expect(source, contains('dailyconversationmaterialcontext:'));
    for (final snippet in [
      'supabasedailykeywordsource',
      'daily_keyword_contexts',
      'dailyopeningcontextprovider',
      'dailyopeningcontextproviderfactory',
      'plant_memories',
    ]) {
      expect(source, isNot(contains(snippet)));
    }
  });
}
