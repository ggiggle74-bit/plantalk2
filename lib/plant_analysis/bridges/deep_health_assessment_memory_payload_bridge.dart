import '../../services/plant_condition_analysis_service.dart';
import 'condition_check_memory_payload_bridge.dart';
import '../models/normalized_plant_event.dart';

class DeepHealthAssessmentMemoryPayloadBridge {
  const DeepHealthAssessmentMemoryPayloadBridge({
    ConditionCheckMemoryPayloadBridge conditionBridge =
        const ConditionCheckMemoryPayloadBridge(),
  }) : _conditionBridge = conditionBridge;

  static const deepHealthAssessmentMemoryType = 'deep_health_assessment';

  final ConditionCheckMemoryPayloadBridge _conditionBridge;

  ConditionCheckMemoryPayload fromNormalizedEvent({
    required NormalizedPlantEvent event,
    required String plantId,
    required String photoUrl,
  }) {
    final conditionPayload = _conditionBridge.fromNormalizedEvent(
      event: event,
      plantId: plantId,
      photoUrl: photoUrl,
    );

    return ConditionCheckMemoryPayload(
      plantId: conditionPayload.plantId,
      memoryType: deepHealthAssessmentMemoryType,
      eventType: PlantConditionEventTypes.normalize(conditionPayload.eventType),
      message: conditionPayload.message,
      photoUrl: conditionPayload.photoUrl,
      isMock: conditionPayload.isMock,
    );
  }
}
