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
  static const uncertain = 'condition_uncertain';

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
  static const _mockUncertainConditionMessage =
      '사진만으로는 상태를 확실히 판단하기 어려워요.';

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
    final conditionMessage = _conditionMessageFrom(normalizedEvent);
    final conditionEvent = NormalizedPlantEvent(
      eventType: normalizedEvent.eventType,
      sourceProvider: normalizedEvent.sourceProvider,
      confidence: normalizedEvent.confidence,
      message: conditionMessage,
      observedAt: normalizedEvent.observedAt,
      sourceResultId: normalizedEvent.sourceResultId,
      isMock: normalizedEvent.isMock,
      metadata: normalizedEvent.metadata,
    );

    return PlantConditionAnalysisResult(
      conditionEventType: _conditionEventTypeFrom(conditionEvent),
      conditionMessage: conditionMessage,
      normalizedEvent: conditionEvent,
      isMock: conditionEvent.isMock,
    );
  }

  String _conditionMessageFrom(NormalizedPlantEvent event) {
    switch (PlantAnalysisEventTypes.normalize(event.eventType)) {
      case PlantAnalysisEventTypes.conditionUncertain:
        return _mockUncertainConditionMessage;
      default:
        return _mockConditionMessage;
    }
  }

  String _conditionEventTypeFrom(NormalizedPlantEvent event) {
    switch (PlantAnalysisEventTypes.normalize(event.eventType)) {
      case PlantAnalysisEventTypes.healthOk:
        return PlantConditionEventTypes.normal;
      case PlantAnalysisEventTypes.conditionUncertain:
        return PlantConditionEventTypes.uncertain;
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
