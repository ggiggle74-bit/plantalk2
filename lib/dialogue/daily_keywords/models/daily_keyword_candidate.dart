class DailyKeywordTypes {
  DailyKeywordTypes._();

  static const weather = 'weather';
  static const calendar = 'calendar';
  static const seasonal = 'seasonal';
  static const safeIssue = 'safe_issue';

  static const allowed = {weather, calendar, seasonal, safeIssue};
}

class DailyKeywordTones {
  DailyKeywordTones._();

  static const gentle = 'gentle';
  static const calm = 'calm';
  static const bright = 'bright';
  static const cautious = 'cautious';

  static const allowed = {gentle, calm, bright, cautious};
}

class DailyKeywordAgeBands {
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

class DailyKeywordCandidate {
  const DailyKeywordCandidate({
    required this.type,
    required this.keyword,
    required this.hint,
    required this.plantHint,
    required this.tone,
    required this.fitScore,
    this.category,
    this.targetAgeBands = const [],
  });

  final String type;
  final String keyword;
  final String hint;
  final String plantHint;
  final String tone;
  final double fitScore;
  final String? category;

  /// Empty means the candidate is suitable for every age band.
  final List<String> targetAgeBands;
}
