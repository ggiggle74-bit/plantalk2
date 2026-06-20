import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/bridges/condition_check_memory_payload_bridge.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';

void main() {
  group('ConditionCheckMemoryPayloadBridge', () {
    test('preserves condition uncertainty and provider message', () {
      const bridge = ConditionCheckMemoryPayloadBridge();
      const providerMessage = '사진이 흐려 상태 판단이 어려워요.';

      final payload = bridge.fromNormalizedEvent(
        event: const NormalizedPlantEvent(
          eventType: PlantAnalysisEventTypes.conditionUncertain,
          sourceProvider: 'test_provider',
          message: providerMessage,
          isMock: true,
        ),
        plantId: 'plant-1',
        photoUrl: 'https://example.test/photo.jpg',
      );

      expect(payload.plantId, 'plant-1');
      expect(payload.photoUrl, 'https://example.test/photo.jpg');
      expect(payload.isMock, isTrue);
      expect(payload.eventType, PlantConditionEventTypes.uncertain);
      expect(payload.eventType, isNot(PlantConditionEventTypes.normal));
      expect(payload.message, providerMessage);
    });

    test(
      'uses cautious fallback for condition uncertainty without message',
      () {
        const bridge = ConditionCheckMemoryPayloadBridge();

        final payload = bridge.fromNormalizedEvent(
          event: const NormalizedPlantEvent(
            eventType: PlantAnalysisEventTypes.conditionUncertain,
            sourceProvider: 'test_provider',
            isMock: true,
          ),
          plantId: 'plant-1',
          photoUrl: 'https://example.test/photo.jpg',
        );

        expect(payload.plantId, 'plant-1');
        expect(payload.photoUrl, 'https://example.test/photo.jpg');
        expect(payload.isMock, isTrue);
        expect(payload.eventType, PlantConditionEventTypes.uncertain);
        expect(payload.eventType, isNot(PlantConditionEventTypes.normal));
        expect(payload.message, '사진만으로는 상태를 확실히 판단하기 어려워요.');
        expect(payload.message, isNot(contains('큰 이상이 없어 보여요')));
      },
    );

    test('keeps health_ok mapped to normal', () {
      const bridge = ConditionCheckMemoryPayloadBridge();

      final payload = bridge.fromNormalizedEvent(
        event: const NormalizedPlantEvent(
          eventType: PlantAnalysisEventTypes.healthOk,
          sourceProvider: 'test_provider',
        ),
        plantId: 'plant-1',
        photoUrl: 'https://example.test/photo.jpg',
      );

      expect(payload.eventType, PlantConditionEventTypes.normal);
    });

    test('keeps water_needed mapped to needs_water', () {
      const bridge = ConditionCheckMemoryPayloadBridge();

      final payload = bridge.fromNormalizedEvent(
        event: const NormalizedPlantEvent(
          eventType: PlantAnalysisEventTypes.waterNeeded,
          sourceProvider: 'test_provider',
        ),
        plantId: 'plant-1',
        photoUrl: 'https://example.test/photo.jpg',
      );

      expect(payload.eventType, PlantConditionEventTypes.needsWater);
    });
  });
}
