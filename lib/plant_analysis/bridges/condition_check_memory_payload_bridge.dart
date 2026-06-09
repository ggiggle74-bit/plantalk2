import '../models/normalized_plant_event.dart';

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
  static const _eventTypeNormal = 'normal';
  static const _eventTypeNeedsWater = 'needs_water';
  static const _eventTypeLowLight = 'low_light';
  static const _eventTypePestRisk = 'pest_risk';
  static const _eventTypeLeafDamage = 'leaf_damage';

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
      case _eventTypeNeedsWater:
        return '사진을 보니 물이 조금 필요해 보여요.';
      case _eventTypeLowLight:
        return '사진을 보니 빛이 조금 부족해 보여요.';
      case _eventTypePestRisk:
        return '사진을 보니 잎 상태를 조금 더 살펴보는 게 좋겠어요.';
      case _eventTypeLeafDamage:
        return '사진을 보니 잎에 스트레스 신호가 조금 보여요.';
      case _eventTypeNormal:
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
      case PlantAnalysisEventTypes.conditionUncertain:
        return _eventTypeNormal;
      case PlantAnalysisEventTypes.waterNeeded:
        return _eventTypeNeedsWater;
      case PlantAnalysisEventTypes.lightNeeded:
        return _eventTypeLowLight;
      case PlantAnalysisEventTypes.pestSuspected:
      case PlantAnalysisEventTypes.diseaseSuspected:
        return _eventTypePestRisk;
      case PlantAnalysisEventTypes.overwaterSuspected:
      case PlantAnalysisEventTypes.tooMuchSunSuspected:
      case PlantAnalysisEventTypes.repottingSuggested:
      case PlantAnalysisEventTypes.soilCheckNeeded:
      case PlantAnalysisEventTypes.temperatureStressSuspected:
      case PlantAnalysisEventTypes.humidityIssueSuspected:
        return _eventTypeLeafDamage;
      default:
        return _eventTypeNormal;
    }
  }
}
