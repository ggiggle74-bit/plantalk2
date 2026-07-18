final class DailyKeywordTypes {
  DailyKeywordTypes._();

  static const weather = 'weather';
  static const calendar = 'calendar';
  static const seasonal = 'seasonal';
  static const safeIssue = 'safe_issue';

  static const allowed = {weather, calendar, seasonal, safeIssue};
}

final class DailyKeywordTones {
  DailyKeywordTones._();

  static const gentle = 'gentle';
  static const calm = 'calm';
  static const bright = 'bright';
  static const cautious = 'cautious';

  static const allowed = {gentle, calm, bright, cautious};
}

final class DailyKeywordAgeBands {
  DailyKeywordAgeBands._();

  static const teens = '10s';
  static const twenties = '20s';
  static const thirties = '30s';
  static const forties = '40s';
  static const fifties = '50s';
  static const sixtiesPlus = '60s_plus';

  static const allowed = {
    teens,
    twenties,
    thirties,
    forties,
    fifties,
    sixtiesPlus,
  };
}

final class DailyKeywordCandidate {
  DailyKeywordCandidate({
    required String type,
    required String keyword,
    required String hint,
    required String plantHint,
    required String tone,
    required this.fitScore,
    required Iterable<String> conversationAngles,
    String? category,
    this.relevanceScore,
    Iterable<String> targetAgeBands = const [],
  }) : type = type.trim().toLowerCase(),
       keyword = keyword.trim(),
       hint = hint.trim(),
       category = _trimToNull(category),
       plantHint = plantHint.trim(),
       tone = tone.trim().toLowerCase(),
       conversationAngles = List.unmodifiable(
         conversationAngles.map((angle) => angle.trim()),
       ),
       targetAgeBands = List.unmodifiable(
         targetAgeBands.map((ageBand) => ageBand.trim().toLowerCase()),
       );

  factory DailyKeywordCandidate.fromJson(Map<String, Object?> json) {
    return DailyKeywordCandidate(
      type: _requiredString(json, 'type'),
      keyword: _requiredString(json, 'keyword'),
      hint: _requiredString(json, 'hint'),
      category: _optionalString(json, 'category'),
      relevanceScore: _optionalDouble(json, 'relevanceScore'),
      plantHint: _requiredString(json, 'plantHint'),
      tone: _requiredString(json, 'tone'),
      fitScore: _requiredDouble(json, 'fitScore'),
      conversationAngles: _requiredStringList(json, 'conversationAngles'),
      targetAgeBands: _optionalStringList(json, 'targetAgeBands'),
    );
  }

  final String type;
  final String keyword;
  final String hint;
  final String? category;
  final double? relevanceScore;
  final String plantHint;
  final String tone;
  final double fitScore;
  final List<String> conversationAngles;

  /// Empty means the candidate is suitable for every age band.
  final List<String> targetAgeBands;

  Map<String, Object?> toJson() {
    return {
      'type': type,
      'keyword': keyword,
      'hint': hint,
      if (category != null) 'category': category,
      if (relevanceScore != null) 'relevanceScore': relevanceScore,
      'plantHint': plantHint,
      'tone': tone,
      'fitScore': fitScore,
      'conversationAngles': conversationAngles,
      if (targetAgeBands.isNotEmpty) 'targetAgeBands': targetAgeBands,
    };
  }

  static String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key must be a string.');
    }
    return value;
  }

  static String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('$key must be a string when present.');
    }
    return value;
  }

  static double _requiredDouble(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException('$key must be a number.');
    }
    return value.toDouble();
  }

  static double? _optionalDouble(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! num) {
      throw FormatException('$key must be a number when present.');
    }
    return value.toDouble();
  }

  static List<String> _requiredStringList(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List<Object?>) {
      throw FormatException('$key must be a list.');
    }
    return _stringList(value, key);
  }

  static List<String> _optionalStringList(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?>) {
      throw FormatException('$key must be a list when present.');
    }
    return _stringList(value, key);
  }

  static List<String> _stringList(List<Object?> value, String key) {
    final result = <String>[];
    for (final item in value) {
      if (item is! String) {
        throw FormatException('$key must contain only strings.');
      }
      result.add(item);
    }
    return result;
  }
}
