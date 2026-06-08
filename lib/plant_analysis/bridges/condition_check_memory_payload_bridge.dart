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

  ConditionCheckMemoryPayload fromNormalizedEvent({
    required NormalizedPlantEvent event,
    required String plantId,
    required String photoUrl,
  }) {
    return ConditionCheckMemoryPayload(
      plantId: plantId,
      memoryType: conditionCheckMemoryType,
      eventType: _conditionMemoryEventType(event.eventType),
      message: _conditionMemoryMessage(event),
      photoUrl: photoUrl,
      isMock: event.isMock,
    );
  }

  String _conditionMemoryMessage(NormalizedPlantEvent event) {
    final message = event.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    return event.eventType;
  }

  String _conditionMemoryEventType(String eventType) {
    switch (PlantAnalysisEventTypes.normalize(eventType)) {
      case PlantAnalysisEventTypes.healthOk:
        return 'normal';
      case PlantAnalysisEventTypes.waterNeeded:
        return 'needs_water';
      case PlantAnalysisEventTypes.lightNeeded:
        return 'low_light';
      case PlantAnalysisEventTypes.pestSuspected:
      case PlantAnalysisEventTypes.diseaseSuspected:
        return 'pest_risk';
      case PlantAnalysisEventTypes.tooMuchSunSuspected:
      case PlantAnalysisEventTypes.temperatureStressSuspected:
      case PlantAnalysisEventTypes.humidityIssueSuspected:
        return 'leaf_damage';
      default:
        return PlantAnalysisEventTypes.normalize(eventType);
    }
  }
}
