import '../plant_analysis/adapters/mock_plant_analysis_adapter.dart';
import '../plant_analysis/models/normalized_plant_event.dart';
import '../plant_analysis/models/plant_analysis_input.dart';
import '../plant_analysis/services/plant_analysis_service.dart';

class PlantConditionEventTypes {
  const PlantConditionEventTypes._();

  static const normal = 'normal';
  static const needsWater = 'needs_water';
  static const waterNeeded = 'water_needed';
  static const lowLight = 'low_light';
  static const pestRisk = 'pest_risk';
  static const leafDamage = 'leaf_damage';

  static String? normalize(String? eventType) {
    final normalized = eventType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    switch (normalized) {
      case waterNeeded:
        return needsWater;
      default:
        return normalized;
    }
  }
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
    required this.normalizedEvent,
    this.isMock = false,
  });

  final String conditionEventType;
  final String conditionMessage;
  final NormalizedPlantEvent normalizedEvent;
  final bool isMock;
}

abstract class PlantConditionAnalysisService {
  Future<PlantConditionAnalysisResult> analyzeCondition(
    PlantConditionAnalysisRequest request,
  );
}

class MockPlantConditionAnalysisService
    implements PlantConditionAnalysisService {
  static const _mockConditionMessage = '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.';

  const MockPlantConditionAnalysisService({
    PlantAnalysisService plantAnalysisService = const PlantAnalysisService(
      adapter: MockPlantAnalysisAdapter(
        mockEventType: PlantAnalysisEventTypes.healthOk,
        mockNote: _mockConditionMessage,
      ),
    ),
  }) : _plantAnalysisService = plantAnalysisService;

  final PlantAnalysisService _plantAnalysisService;

  @override
  Future<PlantConditionAnalysisResult> analyzeCondition(
    PlantConditionAnalysisRequest request,
  ) async {
    final analysisResult = await _plantAnalysisService.analyze(
      PlantAnalysisInput(
        plantId: request.plantId,
        analysisType: PlantAnalysisTypes.conditionCheck,
        speciesKey: request.speciesKey,
        speciesDisplayName: request.speciesDisplayName,
        imageUrl: request.photoUrl,
      ),
    );
    final normalizedEvent = analysisResult.normalizedEvents.first;
    final conditionEvent = NormalizedPlantEvent(
      eventType: normalizedEvent.eventType,
      sourceProvider: normalizedEvent.sourceProvider,
      confidence: normalizedEvent.confidence,
      message: _mockConditionMessage,
      observedAt: normalizedEvent.observedAt,
      sourceResultId: normalizedEvent.sourceResultId,
      isMock: normalizedEvent.isMock,
      metadata: normalizedEvent.metadata,
    );

    return PlantConditionAnalysisResult(
      conditionEventType: _conditionEventTypeFrom(conditionEvent),
      conditionMessage: _mockConditionMessage,
      normalizedEvent: conditionEvent,
      isMock: conditionEvent.isMock,
    );
  }

  String _conditionEventTypeFrom(NormalizedPlantEvent event) {
    switch (PlantAnalysisEventTypes.normalize(event.eventType)) {
      case PlantAnalysisEventTypes.healthOk:
        return PlantConditionEventTypes.normal;
      case PlantAnalysisEventTypes.waterNeeded:
        return PlantConditionEventTypes.needsWater;
      case PlantAnalysisEventTypes.lightNeeded:
        return PlantConditionEventTypes.lowLight;
      case PlantAnalysisEventTypes.pestSuspected:
      case PlantAnalysisEventTypes.diseaseSuspected:
        return PlantConditionEventTypes.pestRisk;
      case PlantAnalysisEventTypes.tooMuchSunSuspected:
      case PlantAnalysisEventTypes.temperatureStressSuspected:
      case PlantAnalysisEventTypes.humidityIssueSuspected:
        return PlantConditionEventTypes.leafDamage;
      default:
        return PlantConditionEventTypes.normalize(event.eventType) ??
            PlantConditionEventTypes.normal;
    }
  }
}
