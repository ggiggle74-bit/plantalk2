import '../plant_analysis/adapters/mock_plant_analysis_adapter.dart';
import '../plant_analysis/models/normalized_plant_event.dart';
import '../plant_analysis/models/plant_analysis_input.dart';
import '../plant_analysis/selectors/plant_condition_representative_event_selector.dart';
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

typedef PlantConditionAnalysisFailureLogger =
    void Function(Object error, StackTrace stackTrace);

class FallbackPlantConditionAnalysisService
    implements PlantConditionAnalysisService {
  const FallbackPlantConditionAnalysisService({
    required PlantConditionAnalysisService primary,
    required PlantConditionAnalysisService fallback,
    required PlantConditionAnalysisFailureLogger onPrimaryFailure,
  }) : _primary = primary,
       _fallback = fallback,
       _onPrimaryFailure = onPrimaryFailure;

  final PlantConditionAnalysisService _primary;
  final PlantConditionAnalysisService _fallback;
  final PlantConditionAnalysisFailureLogger _onPrimaryFailure;

  @override
  Future<PlantConditionAnalysisResult> analyzeCondition(
    PlantConditionAnalysisRequest request,
  ) async {
    try {
      return await _primary.analyzeCondition(request);
    } catch (error, stackTrace) {
      _onPrimaryFailure(error, stackTrace);
      return _fallback.analyzeCondition(request);
    }
  }
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
    PlantConditionRepresentativeEventSelector representativeEventSelector =
        const PlantConditionRepresentativeEventSelector(),
  }) : _plantAnalysisService = plantAnalysisService,
       _representativeEventSelector = representativeEventSelector;

  final PlantAnalysisService _plantAnalysisService;
  final PlantConditionRepresentativeEventSelector _representativeEventSelector;

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
    final normalizedEvent = _representativeEventSelector.select(
      analysisResult.normalizedEvents,
    );
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
    final providerMessage = event.message?.trim();
    if (providerMessage != null && providerMessage.isNotEmpty) {
      return providerMessage;
    }

    switch (PlantAnalysisEventTypes.normalize(event.eventType)) {
      case PlantAnalysisEventTypes.appearanceStable:
        return '사진에서 겉으로 보이는 상태가 비교적 안정적으로 보여요. 건강 진단 결과는 아니에요.';
      case PlantAnalysisEventTypes.healthOk:
        return _mockConditionMessage;
      case PlantAnalysisEventTypes.waterNeeded:
        return '사진을 보니 물이 조금 필요해 보여요.';
      case PlantAnalysisEventTypes.overwaterSuspected:
        return '사진을 보니 물이 많은 신호가 있을 수 있어요. 흙 상태를 먼저 확인해 주세요.';
      case PlantAnalysisEventTypes.lightNeeded:
        return '사진을 보니 빛이 조금 부족해 보여요.';
      case PlantAnalysisEventTypes.tooMuchSunSuspected:
        return '사진을 보니 빛이 강해 잎 스트레스가 있을 수 있어요.';
      case PlantAnalysisEventTypes.pestSuspected:
      case PlantAnalysisEventTypes.diseaseSuspected:
        return '사진을 보니 잎 상태를 조금 더 살펴보는 게 좋겠어요.';
      case PlantAnalysisEventTypes.growthPositive:
      case PlantAnalysisEventTypes.newLeafObserved:
      case PlantAnalysisEventTypes.floweringObserved:
        return '사진을 보니 새 성장 신호가 보여요. 상태는 계속 관찰해 주세요.';
      case PlantAnalysisEventTypes.repottingSuggested:
      case PlantAnalysisEventTypes.soilCheckNeeded:
        return '사진을 보니 흙이나 뿌리 상태를 확인해 보는 게 좋겠어요.';
      case PlantAnalysisEventTypes.temperatureStressSuspected:
      case PlantAnalysisEventTypes.humidityIssueSuspected:
        return '사진을 보니 주변 환경 스트레스가 있을 수 있어요.';
      case PlantAnalysisEventTypes.conditionUncertain:
        return '사진만으로는 상태를 확실히 판단하기 어려워요.';
      default:
        return _mockConditionMessage;
    }
  }

  String _conditionEventTypeFrom(NormalizedPlantEvent event) {
    switch (PlantAnalysisEventTypes.normalize(event.eventType)) {
      case PlantAnalysisEventTypes.appearanceStable:
      case PlantAnalysisEventTypes.healthOk:
      case PlantAnalysisEventTypes.growthPositive:
      case PlantAnalysisEventTypes.newLeafObserved:
      case PlantAnalysisEventTypes.floweringObserved:
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
      case PlantAnalysisEventTypes.overwaterSuspected:
      case PlantAnalysisEventTypes.tooMuchSunSuspected:
      case PlantAnalysisEventTypes.repottingSuggested:
      case PlantAnalysisEventTypes.soilCheckNeeded:
      case PlantAnalysisEventTypes.temperatureStressSuspected:
      case PlantAnalysisEventTypes.humidityIssueSuspected:
        return PlantConditionEventTypes.leafDamage;
      default:
        return PlantConditionEventTypes.normal;
    }
  }
}
