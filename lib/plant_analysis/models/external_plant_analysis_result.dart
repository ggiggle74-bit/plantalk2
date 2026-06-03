class ExternalPlantAnalysisResult {
  const ExternalPlantAnalysisResult({
    required this.providerKey,
    required this.analysisType,
    this.providerResultId,
    this.speciesSuggestions = const [],
    this.conditionEventHints = const [],
    this.summary,
    this.rawPayload = const {},
    this.isMock = false,
    this.createdAt,
  });

  final String providerKey;
  final String analysisType;
  final String? providerResultId;
  final List<ExternalPlantSpeciesSuggestion> speciesSuggestions;
  final List<ExternalPlantConditionEventHint> conditionEventHints;
  final String? summary;
  final Map<String, Object?> rawPayload;
  final bool isMock;
  final DateTime? createdAt;
}

class ExternalPlantSpeciesSuggestion {
  const ExternalPlantSpeciesSuggestion({
    required this.speciesKey,
    this.displayName,
    this.confidence,
  });

  final String speciesKey;
  final String? displayName;
  final double? confidence;
}

class ExternalPlantConditionEventHint {
  const ExternalPlantConditionEventHint({
    required this.eventType,
    this.confidence,
    this.note,
  });

  final String eventType;
  final double? confidence;
  final String? note;
}
