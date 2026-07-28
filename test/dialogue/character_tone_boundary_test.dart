import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local engine uses the generic character tone composer', () {
    final source = File(
      'lib/dialogue/engines/local_casual_conversation_engine.dart',
    ).readAsStringSync();

    expect(source, contains('PlantCharacterToneComposer'));
    expect(source, contains('friendship: request.friendship'));
    expect(source, isNot(contains('MugariToneComposer')));
    expect(source, isNot(contains("'무가리'")));
  });

  test('DB and controller paths do not compose character tone again', () {
    final source = File(
      'lib/dialogue/chat_panel_conversation_controller.dart',
    ).readAsStringSync().toLowerCase();

    expect(source, isNot(contains('tonecomposer')));
    expect(source, isNot(contains('tone_composer')));
    expect(source, isNot(contains('plantcharactertonecomposer')));
  });

  test('composition root only forwards stored character context', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('plantMoodForChat'));
    expect(source, contains('plantFriendshipForChat'));
    expect(source, contains('mood: resolvedMood'));
    expect(source, contains('friendship: resolvedFriendship'));
    expect(source, isNot(contains('PlantCharacterToneComposer')));
  });

  test('generic composer has no fixed character name or legacy suffix', () {
    final source = File(
      'lib/dialogue/tone/plant_character_tone_composer.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('무가리')));
    expect(source, isNot(contains('작게 말해볼게')));
    expect(source, isNot(contains('조금 쑥스럽지만')));
  });
}
