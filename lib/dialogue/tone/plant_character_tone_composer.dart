class PlantCharacterToneComposer {
  const PlantCharacterToneComposer();

  String apply(
    String base, {
    String? plantName,
    String? mood,
    int? friendship,
    String? speciesKey,
    int variantSeed = 0,
  }) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final moodAdjusted = _applyMood(
      trimmed,
      mood: mood,
      variantSeed: variantSeed,
    );
    if (moodAdjusted != trimmed) {
      return moodAdjusted;
    }

    final friendshipAdjusted = _applyFriendship(
      trimmed,
      plantName: plantName,
      friendship: friendship,
      variantSeed: variantSeed,
    );
    if (friendshipAdjusted != trimmed) {
      return friendshipAdjusted;
    }

    return _applySpecies(
      trimmed,
      speciesKey: speciesKey,
      variantSeed: variantSeed,
    );
  }

  String _applyMood(
    String base, {
    required String? mood,
    required int variantSeed,
  }) {
    final normalizedMood = mood?.trim().toLowerCase() ?? '';
    if (normalizedMood.isEmpty ||
        normalizedMood == '보통' ||
        normalizedMood == 'normal' ||
        normalizedMood == 'neutral') {
      return base;
    }

    final List<String> openings;
    if (normalizedMood.contains('shy') ||
        normalizedMood.contains('수줍') ||
        normalizedMood.contains('소심')) {
      openings = const ['음, ', '천천히 말하면, ', '조금 조심스럽게 말하면, '];
    } else if (normalizedMood.contains('cheer') ||
        normalizedMood.contains('happy') ||
        normalizedMood.contains('밝') ||
        normalizedMood.contains('신남') ||
        normalizedMood.contains('좋음')) {
      openings = const ['좋아, ', '반가워. ', '오늘은 기분 좋게, '];
    } else if (normalizedMood.contains('tired') ||
        normalizedMood.contains('sad') ||
        normalizedMood.contains('피곤') ||
        normalizedMood.contains('우울') ||
        normalizedMood.contains('차분')) {
      openings = const ['오늘은 조금 천천히, ', '잠깐 숨을 고르고, ', '지금은 차분하게, '];
    } else {
      return base;
    }

    return '${openings[variantSeed.abs() % openings.length]}$base';
  }

  String _applySpecies(
    String base, {
    required String? speciesKey,
    required int variantSeed,
  }) {
    final key = speciesKey?.trim().toLowerCase() ?? '';
    if (key.isEmpty || key == 'unknown' || variantSeed.abs() % 5 != 0) {
      return base;
    }

    final List<String>? openings = switch (key) {
      'monstera' || 'monstera_deliciosa' => const [
        '잎을 활짝 펼친 기분으로, ',
        '조금 신나게 말하면, ',
      ],
      'stucky' || 'sansevieria' => const [
        '차분하게 한마디 보태면, ',
        '서두르지 않고 말하면, ',
      ],
      'pothos' || 'philodendron' || 'ivy' => const [
        '살짝 궁금한 건, ',
        '네 이야기 쪽으로 마음을 뻗어 보면, ',
      ],
      'rubber_tree' ||
      'dracaena_fragrans' ||
      'pachira' ||
      'schefflera' ||
      'areca_palm' => const [
        '든든하게 곁에서 말하면, ',
        '천천히 생각해 보면, ',
      ],
      'alocasia' || 'calathea' || 'peperomia' => const [
        '조금 세심하게 살펴보면, ',
        '오늘 분위기를 느껴 보면, ',
      ],
      'succulent' || 'cactus' => const [
        '짧고 솔직하게 말하면, ',
        '꾸밈없이 말하면, ',
      ],
      _ => null,
    };

    if (openings == null) {
      return base;
    }
    final openingIndex = (variantSeed.abs() ~/ 5) % openings.length;
    return '${openings[openingIndex]}$base';
  }

  String _applyFriendship(
    String base, {
    required String? plantName,
    required int? friendship,
    required int variantSeed,
  }) {
    final name = plantName?.trim() ?? '';
    final score = friendship ?? 0;
    if (name.isEmpty || score < 10 || variantSeed.abs() % 3 != 0) {
      return base;
    }

    final openings = [
      '$name, 이제 네가 오면 바로 알아봐. ',
      '$name도 네 목소리가 꽤 익숙해졌어. ',
      '$name, 오늘도 네가 와서 마음이 놓여. ',
    ];
    final openingIndex = (variantSeed.abs() ~/ 3) % openings.length;
    return '${openings[openingIndex]}$base';
  }
}
