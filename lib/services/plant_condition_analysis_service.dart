class PlantConditionEventTypes {
  const PlantConditionEventTypes._();

  static const normal = 'normal';
  static const needsWater = 'needs_water';
  static const lowLight = 'low_light';
  static const pestRisk = 'pest_risk';
  static const leafDamage = 'leaf_damage';
}

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

class MockPlantConditionAnalysisService
    implements PlantConditionAnalysisService {
  @override
  Future<PlantConditionAnalysisResult> analyzeCondition(
    PlantConditionAnalysisRequest request,
  ) async {
    return const PlantConditionAnalysisResult(
      conditionEventType: PlantConditionEventTypes.normal,
      conditionMessage: '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.',
      isMock: true,
    );
  }
}
