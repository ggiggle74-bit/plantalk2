import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/kindwise_plant_health_response_parser.dart';
import 'package:plantalk2/plant_analysis/adapters/supabase_kindwise_plant_health_proxy.dart';
import 'package:plantalk2/plant_analysis/factories/kindwise_plant_health_service_factory.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/plant_analysis/services/plant_analysis_service.dart';

void main() {
  test('factory creates a PlantAnalysisService without invoking proxy', () {
    var callCount = 0;
    final factory = KindwisePlantHealthServiceFactory.withProxyCallback(
      invokeProxy: ({required imageUrl}) async {
        callCount += 1;
        return _healthyPayload();
      },
    );

    final service = factory.build();

    expect(service, isA<PlantAnalysisService>());
    expect(callCount, 0);
  });

  test('created service analyzes condition_check through fake proxy', () async {
    var callCount = 0;
    String? receivedImageUrl;
    final service = KindwisePlantHealthServiceFactory.withProxyCallback(
      invokeProxy: ({required imageUrl}) async {
        callCount += 1;
        receivedImageUrl = imageUrl;
        return _healthyPayload();
      },
    ).build();

    final result = await service.analyze(_input());

    expect(callCount, 1);
    expect(receivedImageUrl, 'https://example.test/photo.jpg');
    expect(
      result.externalResult.providerKey,
      KindwisePlantHealthResponseParser.providerKey,
    );
    expect(
      result.externalResult.analysisType,
      PlantAnalysisTypes.conditionCheck,
    );
    expect(result.externalResult.rawPayload, isEmpty);
    expect(result.normalizedEvents, hasLength(1));

    final event = result.normalizedEvents.single;
    expect(event.sourceProvider, KindwisePlantHealthResponseParser.providerKey);
    expect(event.eventType, PlantAnalysisEventTypes.healthOk);
    expect(event.confidence, 0.94);
    expect(event.sourceResultId, 'fake-kindwise-token');
    expect(
      event.observedAt,
      DateTime.fromMillisecondsSinceEpoch(1782057600000, isUtc: true),
    );
    expect(event.metadata, {'analysisType': PlantAnalysisTypes.conditionCheck});
  });

  test(
    'supabase invoker path calls plant-health-assess with imageUrl only',
    () async {
      final calls = <Map<String, Object?>>[];
      final factory =
          KindwisePlantHealthServiceFactory.withSupabaseFunctionInvoker(
            invokeFunction: ({required functionName, required body}) async {
              calls.add({'functionName': functionName, 'body': body});
              return _healthyPayload();
            },
          );

      expect(calls, isEmpty);

      final result = await factory.build().analyze(
        const PlantAnalysisInput(
          plantId: 'private-plant-id',
          analysisType: PlantAnalysisTypes.conditionCheck,
          speciesKey: 'private-species-key',
          speciesDisplayName: 'Private plant',
          imagePath: r'C:\private\photo.jpg',
          imageUrl: 'https://example.test/private-photo.jpg',
          userPrompt: 'private prompt',
          metadata: {'private': 'metadata'},
        ),
      );

      expect(
        result.normalizedEvents.single.eventType,
        PlantAnalysisEventTypes.healthOk,
      );
      expect(calls, hasLength(1));
      expect(
        calls.single['functionName'],
        SupabaseKindwisePlantHealthProxy.defaultFunctionName,
      );
      expect(calls.single['body'], {
        'imageUrl': 'https://example.test/private-photo.jpg',
      });
      expect(calls.single['body'], isNot(containsPair('plantId', anything)));
      expect(calls.single['body'], isNot(containsPair('plantName', anything)));
      expect(calls.single['body'], isNot(containsPair('userId', anything)));
      expect(calls.single['body'], isNot(containsPair('metadata', anything)));
      expect(calls.single['body'], isNot(containsPair('userPrompt', anything)));
      expect(calls.single['body'], isNot(containsPair('imagePath', anything)));
    },
  );

  test('supabase proxy path can use an injected proxy', () async {
    final calls = <Map<String, Object?>>[];
    final proxy = SupabaseKindwisePlantHealthProxy(
      invokeFunction: ({required functionName, required body}) async {
        calls.add({'functionName': functionName, 'body': body});
        return _healthyPayload();
      },
    );
    final service = KindwisePlantHealthServiceFactory.supabase(
      proxy: proxy,
    ).build();

    await service.analyze(_input());

    expect(calls, hasLength(1));
    expect(calls.single['body'], {
      'imageUrl': 'https://example.test/photo.jpg',
    });
  });

  test(
    'non-condition-check input is rejected without invoking proxy',
    () async {
      for (final analysisType in const [
        PlantAnalysisTypes.defaultObservation,
        PlantAnalysisTypes.identification,
        PlantAnalysisTypes.combined,
        'unknown_analysis',
      ]) {
        var callCount = 0;
        final service = KindwisePlantHealthServiceFactory.withProxyCallback(
          invokeProxy: ({required imageUrl}) async {
            callCount += 1;
            return _healthyPayload();
          },
        ).build();

        await expectLater(
          service.analyze(_input(analysisType: analysisType)),
          throwsA(isA<UnsupportedError>()),
        );
        expect(callCount, 0);
      }
    },
  );
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

PlantAnalysisInput _input({
  String analysisType = PlantAnalysisTypes.conditionCheck,
}) {
  return PlantAnalysisInput(
    plantId: 'test-plant',
    analysisType: analysisType,
    imageUrl: 'https://example.test/photo.jpg',
    requestedAt: DateTime.utc(2026, 6, 22),
  );
}
