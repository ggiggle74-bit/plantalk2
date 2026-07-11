class DailyKeywordTypes {
  DailyKeywordTypes._();

  static const weather = 'weather';
  static const calendar = 'calendar';
  static const seasonal = 'seasonal';

  static const allowed = {weather, calendar, seasonal};
}

class DailyKeywordTones {
  DailyKeywordTones._();

  static const gentle = 'gentle';
  static const calm = 'calm';
  static const bright = 'bright';
  static const cautious = 'cautious';

  static const allowed = {gentle, calm, bright, cautious};
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
  });

  final String type;
  final String keyword;
  final String hint;
  final String plantHint;
  final String tone;
  final double fitScore;
  final String? category;
}
