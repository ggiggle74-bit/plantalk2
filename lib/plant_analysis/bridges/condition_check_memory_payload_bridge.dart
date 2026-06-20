import '../models/normalized_plant_event.dart';
import '../../services/plant_condition_analysis_service.dart';

class ConditionCheckMemoryPayload {
  const ConditionCheckMemoryPayload({
    required this.plantId,
    required this.memoryType,
    required this.message,
    required this.photoUrl,
    this.eventType,
    this.isMock = false,
  });

  final String plantId;
  final String memoryType;
  final String? eventType;
  final String message;
  final String photoUrl;
  final bool isMock;
}

class ConditionCheckMemoryPayloadBridge {
  const ConditionCheckMemoryPayloadBridge();

  static const conditionCheckMemoryType = 'condition_check';

  ConditionCheckMemoryPayload fromNormalizedEvent({
    required NormalizedPlantEvent event,
    required String plantId,
    required String photoUrl,
  }) {
    final conditionEventType = _conditionMemoryEventType(event.eventType);

    return ConditionCheckMemoryPayload(
      plantId: plantId,
      memoryType: conditionCheckMemoryType,
      eventType: conditionEventType,
      message: _conditionMemoryMessage(event, conditionEventType),
      photoUrl: photoUrl,
      isMock: event.isMock,
    );
  }

  String _conditionMemoryMessage(
    NormalizedPlantEvent event,
    String conditionEventType,
  ) {
    final message = event.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    switch (conditionEventType) {
      case PlantConditionEventTypes.needsWater:
        return '사진을 보니 물이 조금 필요해 보여요.';
      case PlantConditionEventTypes.lowLight:
        return '사진을 보니 빛이 조금 부족해 보여요.';
      case PlantConditionEventTypes.pestRisk:
        return '사진을 보니 잎 상태를 조금 더 살펴보는 게 좋겠어요.';
      case PlantConditionEventTypes.leafDamage:
        return '사진을 보니 잎에 스트레스 신호가 조금 보여요.';
      case PlantConditionEventTypes.uncertain:
        return '사진만으로는 상태를 확실히 판단하기 어려워요.';
      case PlantConditionEventTypes.normal:
      default:
        return '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.';
    }
  }

  String _conditionMemoryEventType(String eventType) {
    switch (PlantAnalysisEventTypes.normalize(eventType)) {
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
