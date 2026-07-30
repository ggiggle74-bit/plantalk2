import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/bridges/deep_health_assessment_memory_payload_bridge.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';

void main() {
  const bridge = DeepHealthAssessmentMemoryPayloadBridge();

  test('uses a memory type separate from ordinary condition checks', () {
    const event = NormalizedPlantEvent(
      eventType: PlantAnalysisEventTypes.pestSuspected,
      sourceProvider: 'kindwise',
      confidence: 0.81,
      message: '잎 뒷면에 해충 신호가 의심돼요.',
      sourceResultId: 'health-1',
    );

    final payload = bridge.fromNormalizedEvent(
      event: event,
      plantId: 'plant-1',
      photoUrl: 'https://example.test/deep-health.jpg',
    );

    expect(
      payload.memoryType,
      DeepHealthAssessmentMemoryPayloadBridge
          .deepHealthAssessmentMemoryType,
    );
    expect(payload.memoryType, isNot('condition_check'));
    expect(payload.eventType, PlantConditionEventTypes.pestRisk);
    expect(payload.message, '잎 뒷면에 해충 신호가 의심돼요.');
    expect(payload.photoUrl, 'https://example.test/deep-health.jpg');
    expect(payload.isMock, isFalse);
  });

  test('preserves explicit mock provenance', () {
    const event = NormalizedPlantEvent(
      eventType: PlantAnalysisEventTypes.healthOk,
      sourceProvider: 'mock',
      confidence: 1,
      message: '테스트용 결과예요.',
      isMock: true,
    );

    final payload = bridge.fromNormalizedEvent(
      event: event,
      plantId: 'plant-1',
      photoUrl: 'https://example.test/mock.jpg',
    );

    expect(payload.eventType, PlantConditionEventTypes.normal);
    expect(payload.isMock, isTrue);
  });
}
