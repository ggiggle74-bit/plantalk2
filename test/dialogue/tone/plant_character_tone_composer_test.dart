import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/tone/plant_character_tone_composer.dart';

void main() {
  const composer = PlantCharacterToneComposer();

  test('keeps a neutral local reply unchanged', () {
    final reply = composer.apply(
      '오늘은 어떤 하루였어?',
      plantName: '초록이',
      mood: '보통',
      friendship: 4,
      variantSeed: 0,
    );

    expect(reply, '오늘은 어떤 하루였어?');
  });

  test('expresses a shy mood without a fixed suffix', () {
    final reply = composer.apply(
      '오늘은 어떤 하루였어?',
      plantName: '초록이',
      mood: '수줍음',
      friendship: 4,
      variantSeed: 0,
    );

    expect(reply, '음, 오늘은 어떤 하루였어?');
    expect(reply, isNot(contains('작게 말')));
    expect(reply, isNot(contains('쑥스럽지만')));
  });

  test('rotates cheerful openings by reply seed', () {
    final first = composer.apply(
      '오늘도 이야기해볼까?',
      mood: '밝음',
      variantSeed: 0,
    );
    final second = composer.apply(
      '오늘도 이야기해볼까?',
      mood: '밝음',
      variantSeed: 1,
    );

    expect(first, '좋아, 오늘도 이야기해볼까?');
    expect(second, '반가워. 오늘도 이야기해볼까?');
    expect(first, isNot(second));
  });

  test('uses the actual plant name only at a high friendship checkpoint', () {
    final closeReply = composer.apply(
      '오늘은 어떤 하루였어?',
      plantName: '초록이',
      mood: '보통',
      friendship: 10,
      variantSeed: 0,
    );
    final earlyReply = composer.apply(
      '오늘은 어떤 하루였어?',
      plantName: '초록이',
      mood: '보통',
      friendship: 9,
      variantSeed: 0,
    );

    expect(closeReply, startsWith('초록이, '));
    expect(closeReply, isNot(contains('무가리')));
    expect(earlyReply, '오늘은 어떤 하루였어?');
  });

  test('does not prepend a relationship line on every close-friend reply', () {
    final reply = composer.apply(
      '오늘도 이야기해볼까?',
      plantName: '새싹',
      mood: '보통',
      friendship: 20,
      variantSeed: 1,
    );

    expect(reply, '오늘도 이야기해볼까?');
  });
}
