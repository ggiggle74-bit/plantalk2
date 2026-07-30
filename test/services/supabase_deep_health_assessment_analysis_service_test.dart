import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/supabase_kindwise_plant_health_proxy.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';
import 'package:plantalk2/services/supabase_deep_health_assessment_analysis_service.dart';

void main() {
  test('passes the server reservation only on the deep Kindwise request',
      () async {
    final calls = <Map<String, Object?>>[];
    final service = SupabaseDeepHealthAssessmentAnalysisService(
      proxy: SupabaseKindwisePlantHealthProxy(
        invokeFunction: ({required functionName, required body}) async {
          calls.add({'functionName': functionName, 'body': body});
          return _healthyPayload();
        },
      ),
    );

    final result = await service.analyzeCondition(
      const PlantConditionAnalysisRequest(
        plantId: 'plant-1',
        photoUrl: 'https://example.test/deep-health.jpg',
        deepHealthReservationId: 'reservation-1',
      ),
    );

    expect(result.isMock, isFalse);
    expect(result.conditionMessage, isNotEmpty);
    expect(calls, [
      {
        'functionName': 'plant-health-assess',
        'body': {
          'imageUrl': 'https://example.test/deep-health.jpg',
          'reservationId': 'reservation-1',
        },
      },
    ]);
  });

  test('refuses a deep provider call without a reservation', () async {
    var callCount = 0;
    final service = SupabaseDeepHealthAssessmentAnalysisService(
      proxy: SupabaseKindwisePlantHealthProxy(
        invokeFunction: ({required functionName, required body}) async {
          callCount += 1;
          return _healthyPayload();
        },
      ),
    );

    await expectLater(
      service.analyzeCondition(
        const PlantConditionAnalysisRequest(
          plantId: 'plant-1',
          photoUrl: 'https://example.test/deep-health.jpg',
        ),
      ),
      throwsStateError,
    );
    expect(callCount, 0);
  });

  test('rejects an empty reservation before invoking Supabase', () async {
    var callCount = 0;
    final service = SupabaseDeepHealthAssessmentAnalysisService(
      proxy: SupabaseKindwisePlantHealthProxy(
        invokeFunction: ({required functionName, required body}) async {
          callCount += 1;
          return _healthyPayload();
        },
      ),
    );

    await expectLater(
      service.analyzeCondition(
        const PlantConditionAnalysisRequest(
          plantId: 'plant-1',
          photoUrl: 'https://example.test/deep-health.jpg',
          deepHealthReservationId: '  ',
        ),
      ),
      throwsStateError,
    );
    expect(callCount, 0);
  });
}

Map<String, dynamic> _healthyPayload() {
  return {
    'access_token': 'fake-kindwise-token',
    'created': 1782057600,
    'status': 'COMPLETED',
    'result': {
      'is_healthy': {'binary': true, 'probability': 0.94, 'threshold': 0.63},
      'disease': {'suggestions': const []},
    },
  };
}
