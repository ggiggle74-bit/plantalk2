class PlantConditionAnalysisRequest {
  const PlantConditionAnalysisRequest({
    required this.plantId,
    required this.photoUrl,
    this.speciesKey,
    this.speciesDisplayName,
  });

  final String plantId;
  final String photoUrl;
  final String? speciesKey;
  final String? speciesDisplayName;
}

class PlantConditionAnalysisResult {
  const PlantConditionAnalysisResult({
    required this.conditionEventType,
    required this.conditionMessage,
    this.isMock = false,
  });

  final String conditionEventType;
  final String conditionMessage;
  final bool isMock;
}

abstract class PlantConditionAnalysisService {
  Future<PlantConditionAnalysisResult> analyzeCondition(
    PlantConditionAnalysisRequest request,
  );
}
