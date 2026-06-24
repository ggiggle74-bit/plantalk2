class PlantAnalysisInput {
  const PlantAnalysisInput({
    required this.plantId,
    required this.analysisType,
    this.speciesKey,
    this.speciesDisplayName,
    this.imagePath,
    this.imageUrl,
    this.userPrompt,
    this.requestedAt,
    this.metadata = const {},
  });

  final String plantId;
  final String analysisType;
  final String? speciesKey;
  final String? speciesDisplayName;
  final String? imagePath;
  final String? imageUrl;
  final String? userPrompt;
  final DateTime? requestedAt;
  final Map<String, Object?> metadata;
}

class PlantAnalysisTypes {
  const PlantAnalysisTypes._();

  static const identification = 'identification';
  static const defaultObservation = 'default_observation';
  static const conditionCheck = 'condition_check';
  static const combined = 'combined';
}
