class DailyConversationMaterialContext {
  DailyConversationMaterialContext({
    required this.date,
    required this.locale,
    required Iterable<DailyConversationMaterial> materials,
    this.generatedAt,
    this.sourceVersion,
  }) : materials = List.unmodifiable(materials);

  final DateTime date;
  final String locale;
  final List<DailyConversationMaterial> materials;
  final DateTime? generatedAt;
  final String? sourceVersion;

  bool get hasMaterials => materials.isNotEmpty;
}

class DailyConversationMaterial {
  DailyConversationMaterial({
    required this.type,
    required this.keyword,
    required this.hint,
    required this.plantHint,
    required this.tone,
    required this.fitScore,
    this.category,
    this.relevanceScore,
    Iterable<String> targetAgeBands = const [],
  }) : targetAgeBands = List.unmodifiable(targetAgeBands);

  final String type;
  final String keyword;
  final String hint;
  final String plantHint;
  final String tone;
  final double fitScore;
  final String? category;
  final double? relevanceScore;
  final List<String> targetAgeBands;
}
