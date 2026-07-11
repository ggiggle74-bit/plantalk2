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
        'lib/main.dart',
      ];

      for (final path in files) {
        final source = File(path).readAsStringSync().toLowerCase();
        expect(source, isNot(contains('localdailykeywordsource')));
        expect(source, isNot(contains('local_daily_keyword_source')));
      }
    },
  );
}
