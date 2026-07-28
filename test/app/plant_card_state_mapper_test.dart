import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/app/plant_card_state_mapper.dart';

void main() {
  test('maps stored mood and friendship for the selected chat plant', () {
    final plants = <Map<String, dynamic>>[
      {
        'id': 'plant-1',
        'name': '초록이',
        'mood': '밝음',
        'friendship': 12,
      },
      {
        'id': 'plant-2',
        'name': '새싹',
        'mood': '차분',
        'friendship': '7',
      },
    ];

    expect(plantMoodForChat('plant-1', plants), '밝음');
    expect(plantFriendshipForChat('plant-1', plants), 12);
    expect(plantMoodForChat('plant-2', plants), '차분');
    expect(plantFriendshipForChat('plant-2', plants), 7);
  });

  test('returns null when the selected plant has no usable state', () {
    final plants = <Map<String, dynamic>>[
      {
        'id': 'plant-1',
        'name': '초록이',
        'mood': '  ',
        'friendship': 'unknown',
      },
    ];

    expect(plantMoodForChat('plant-1', plants), isNull);
    expect(plantFriendshipForChat('plant-1', plants), isNull);
    expect(plantMoodForChat('missing', plants), isNull);
    expect(plantFriendshipForChat(null, plants), isNull);
  });

  test('keeps mood and friendship when mapping a Supabase row', () {
    final state = plantCardStateFromSupabaseRow({
      'id': 'plant-1',
      'name': '초록이',
      'mood': '수줍음',
      'friendship': 8,
    });

    expect(state['mood'], '수줍음');
    expect(state['friendship'], 8);
  });

  test('returns only a stored canonical species key for chat', () {
    final plants = <Map<String, dynamic>>[
      {
        'id': 'plant-1',
        'speciesKey': '  MONSTERA ',
        'speciesDisplayName': '사용자가 바꾼 표시 이름',
      },
      {
        'id': 'plant-2',
        'speciesKey': 'unknown',
        'speciesDisplayName': '몬스테라',
      },
    ];

    expect(speciesKeyForChat('plant-1', plants), 'monstera');
    expect(speciesKeyForChat('plant-2', plants), isNull);
    expect(speciesKeyForChat('missing', plants), isNull);
  });

}
