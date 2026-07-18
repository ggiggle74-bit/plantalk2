class DailyKeywordContext {
  DailyKeywordContext({
    required this.date,
    required this.locale,
    required List<DailyKeywordEntry> keywords,
    this.generatedAt,
    this.sourceVersion,
  }) : keywords = List.unmodifiable(keywords);

  final DateTime date;
  final String locale;
  final List<DailyKeywordEntry> keywords;
  final DateTime? generatedAt;
  final String? sourceVersion;

  bool get hasKeywords => keywords.isNotEmpty;

  DailyKeywordEntry? pickForSeed(int seed) {
    if (keywords.isEmpty) {
      return null;
    }

    final index = seed.remainder(keywords.length).abs();
    return keywords[index];
  }
}

class DailyKeywordEntry {
  const DailyKeywordEntry({
    required this.type,
    required this.keyword,
    required this.hint,
    this.category,
    this.relevanceScore,
    this.plantHint,
    this.tone,
    this.fitScore,
    this.targetAgeBands = const [],
  });

  final String type;
  final String keyword;
  final String hint;
  final String? category;
  final double? relevanceScore;
  final String? plantHint;
  final String? tone;
  final double? fitScore;

  /// Empty means the candidate is suitable for every age band.
  final List<String> targetAgeBands;
}
