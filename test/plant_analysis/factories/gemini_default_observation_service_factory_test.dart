import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/gemini_default_state_observation_parser.dart';
import 'package:plantalk2/plant_analysis/adapters/supabase_gemini_default_observation_proxy.dart';
import 'package:plantalk2/plant_analysis/factories/gemini_default_observation_service_factory.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';

void main() {
  test('builds a default_observation service that preserves events', () async {
    final service = GeminiDefaultObservationServiceFactory.withProxyCallback(
      invokeProxy: ({required imageUrl}) async => _stablePayload(),
    ).build();

    final result = await service.analyze(_input());

    expect(
      result.externalResult.providerKey,
      GeminiDefaultStateObservationParser.providerKey,
    );
    expect(
      result.externalResult.analysisType,
      PlantAnalysisTypes.defaultObservation,
    );
    expect(result.externalResult.rawPayload, isEmpty);
    expect(result.normalizedEvents, hasLength(1));

    final event = result.normalizedEvents.single;
    expect(
      event.sourceProvider,
      GeminiDefaultStateObservationParser.providerKey,
    );
    expect(event.eventType, PlantAnalysisEventTypes.appearanceStable);
    expect(event.sourceResultId, 'observation-1');
    expect(event.observedAt, DateTime.parse('2026-06-24T01:02:03Z'));
    expect(event.metadata, {
      'analysisType': PlantAnalysisTypes.defaultObservation,
    });
  });

  test('injected fake proxy receives only imageUrl', () async {
    var callCount = 0;
    String? receivedImageUrl;
    final service = GeminiDefaultObservationServiceFactory.withProxyCallback(
      invokeProxy: ({required imageUrl}) async {
        callCount += 1;
        receivedImageUrl = imageUrl;
        return _stablePayload();
      },
    ).build();

    await service.analyze(
      const PlantAnalysisInput(
        plantId: 'private-plant-id',
        analysisType: PlantAnalysisTypes.defaultObservation,
        speciesKey: 'private-species-key',
        speciesDisplayName: 'Private plant',
        imagePath: r'C:\private\photo.jpg',
        imageUrl: 'https://example.test/private-photo.jpg',
        userPrompt: 'private prompt',
        metadata: {'private': 'metadata'},
      ),
    );

    expect(callCount, 1);
    expect(receivedImageUrl, 'https://example.test/private-photo.jpg');
  });

  test('supabase factory path supports injected proxy invoker', () async {
    final calls = <Map<String, Object?>>[];
    final proxy = SupabaseGeminiDefaultObservationProxy(
      invokeFunction: ({required functionName, required body}) async {
        calls.add({'functionName': functionName, 'body': body});
        return _stablePayload();
      },
    );
    final service = GeminiDefaultObservationServiceFactory.supabase(
      proxy: proxy,
    ).build();

    final result = await service.analyze(_input());

    expect(
      result.externalResult.providerKey,
      GeminiDefaultStateObservationParser.providerKey,
    );
    expect(calls, hasLength(1));
    expect(
      calls.single['functionName'],
      SupabaseGeminiDefaultObservationProxy.defaultFunctionName,
    );
    expect(calls.single['body'], {
      'imageUrl': 'https://example.test/photo.jpg',
    });
  });

  test(
    'condition_check remains unsupported and does not invoke proxy',
    () async {
      var callCount = 0;
      final service = GeminiDefaultObservationServiceFactory.withProxyCallback(
        invokeProxy: ({required imageUrl}) async {
          callCount += 1;
          return _stablePayload();
        },
      ).build();

      await expectLater(
        service.analyze(
          _input(analysisType: PlantAnalysisTypes.conditionCheck),
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(callCount, 0);
    },
  );
}

Map<String, dynamic> _stablePayload() {
  return {
    'observation_id': 'observation-1',
    'observed_at': '2026-06-24T01:02:03Z',
    'image_quality': 'usable',
    'observation_state': 'stable_appearance',
    'evidence_tags': ['stable_foliage'],
    'summary_ko': '이 식물은 완벽하게 건강합니다.',
    'diagnosis': '확정 진단',
    'recommended_action': '약제를 사용하세요.',
    'confidence': 0.99,
  };
}

PlantAnalysisInput _input({
  String analysisType = PlantAnalysisTypes.defaultObservation,
}) {
  return PlantAnalysisInput(
    plantId: 'test-plant',
    analysisType: analysisType,
    imageUrl: 'https://example.test/photo.jpg',
    requestedAt: DateTime.utc(2026, 6, 24),
  );
}
