import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/kindwise_plant_health_adapter.dart';
import 'package:plantalk2/plant_analysis/adapters/kindwise_plant_health_response_parser.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/plant_analysis/services/plant_analysis_service.dart';

void main() {
  test('providerKey identifies Kindwise plant.health', () {
    final adapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async => _healthyFixtureMap(),
    );

    expect(adapter.providerKey, KindwisePlantHealthResponseParser.providerKey);
  });

  test('parses direct map response after trimming imageUrl', () async {
    var callCount = 0;
    String? receivedImageUrl;
    final adapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async {
        callCount += 1;
        receivedImageUrl = imageUrl;
        return _healthyFixtureMap();
      },
    );

    final result = await adapter.analyze(
      _input(imageUrl: '  https://example.test/condition-photo.jpg  '),
    );

    expect(callCount, 1);
    expect(receivedImageUrl, 'https://example.test/condition-photo.jpg');
    expect(result.providerKey, KindwisePlantHealthResponseParser.providerKey);
    expect(result.analysisType, PlantAnalysisTypes.conditionCheck);
    expect(result.rawPayload, isEmpty);
    expect(result.conditionEventHints, hasLength(1));
    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.healthOk,
    );
  });

  test('parses JSON string response', () async {
    final adapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async =>
          _fixture('health_unhealthy_mixed_response.json'),
    );

    final result = await adapter.analyze(_input());

    expect(result.conditionEventHints.map((hint) => hint.eventType), [
      PlantAnalysisEventTypes.pestSuspected,
      PlantAnalysisEventTypes.overwaterSuspected,
      PlantAnalysisEventTypes.diseaseSuspected,
    ]);
  });

  test(
    'works through PlantAnalysisService without changing normalized events',
    () async {
      final service = PlantAnalysisService(
        adapter: KindwisePlantHealthAdapter(
          invokeProxy: ({required imageUrl}) async =>
              _fixture('health_unhealthy_mixed_response.json'),
        ),
      );

      final result = await service.analyze(_input());

      expect(
        result.externalResult.providerKey,
        KindwisePlantHealthResponseParser.providerKey,
      );
      expect(result.externalResult.conditionEventHints, hasLength(3));

      final pestEvent = result.normalizedEvents.singleWhere(
        (event) => event.eventType == PlantAnalysisEventTypes.pestSuspected,
      );
      expect(pestEvent.confidence, 0.72);
      expect(pestEvent.message, '사진에서 해충 피해 관련 신호가 있을 수 있어요.');
    },
  );

  test('proxy callback contract exposes only imageUrl', () async {
    var callCount = 0;
    String? receivedImageUrl;
    final adapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async {
        callCount += 1;
        receivedImageUrl = imageUrl;
        return _healthyFixtureMap();
      },
    );

    await adapter.analyze(
      PlantAnalysisInput(
        plantId: 'private-plant-id',
        analysisType: PlantAnalysisTypes.conditionCheck,
        speciesKey: 'private-species-key',
        speciesDisplayName: 'Private plant',
        imagePath: r'C:\private\photo.jpg',
        imageUrl: 'https://example.test/private-photo.jpg',
        userPrompt: 'private prompt',
        requestedAt: DateTime.utc(2026, 6, 22, 1, 2, 3),
        metadata: const {'private': 'metadata'},
      ),
    );

    expect(callCount, 1);
    expect(receivedImageUrl, 'https://example.test/private-photo.jpg');
  });

  test('rejects unsupported analysis types without invoking proxy', () async {
    for (final analysisType in const [
      PlantAnalysisTypes.identification,
      PlantAnalysisTypes.combined,
      'unknown_analysis',
    ]) {
      var callCount = 0;
      final adapter = KindwisePlantHealthAdapter(
        invokeProxy: ({required imageUrl}) async {
          callCount += 1;
          return _healthyFixtureMap();
        },
      );

      await expectLater(
        adapter.analyze(_input(analysisType: analysisType)),
        throwsA(isA<UnsupportedError>()),
      );
      expect(callCount, 0);
    }
  });

  test('rejects missing or blank imageUrl without invoking proxy', () async {
    for (final imageUrl in const <String?>[null, '', '   ']) {
      var callCount = 0;
      final adapter = KindwisePlantHealthAdapter(
        invokeProxy: ({required imageUrl}) async {
          callCount += 1;
          return _healthyFixtureMap();
        },
      );

      await expectLater(
        adapter.analyze(_input(imageUrl: imageUrl)),
        throwsA(isA<StateError>()),
      );
      expect(callCount, 0);
    }
  });

  test('rejects invalid remote image URLs without invoking proxy', () async {
    for (final imageUrl in const [
      'relative/photo.jpg',
      r'C:\photos\plant.jpg',
      'file:///tmp/plant.jpg',
      'data:image/jpeg;base64,fake',
      'ftp://example.test/plant.jpg',
      'https:///missing-host.jpg',
    ]) {
      var callCount = 0;
      final adapter = KindwisePlantHealthAdapter(
        invokeProxy: ({required imageUrl}) async {
          callCount += 1;
          return _healthyFixtureMap();
        },
      );

      await expectLater(
        adapter.analyze(_input(imageUrl: imageUrl)),
        throwsA(isA<StateError>()),
      );
      expect(callCount, 0);
    }
  });

  test('accepts HTTP and HTTPS image URLs', () async {
    for (final imageUrl in const [
      'http://localhost:54321/storage/v1/object/public/plant-photos/photo.jpg',
      'https://example.test/photo.jpg',
    ]) {
      String? receivedImageUrl;
      final adapter = KindwisePlantHealthAdapter(
        invokeProxy: ({required imageUrl}) async {
          receivedImageUrl = imageUrl;
          return _healthyFixtureMap();
        },
      );

      await adapter.analyze(_input(imageUrl: '  $imageUrl  '));

      expect(receivedImageUrl, imageUrl);
    }
  });

  test('parses supported response map forms', () async {
    final mapStringDynamicAdapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async => _healthyFixtureMap(),
    );
    final mapObjectAdapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async =>
          Map<Object?, Object?>.from(_healthyFixtureMap()),
    );

    final directResult = await mapStringDynamicAdapter.analyze(_input());
    final convertedResult = await mapObjectAdapter.analyze(_input());

    expect(
      directResult.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.healthOk,
    );
    expect(
      convertedResult.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.healthOk,
    );
  });

  test(
    'throws FormatException for unsupported proxy response shapes',
    () async {
      for (final response in const [null, [], 42, true]) {
        final adapter = KindwisePlantHealthAdapter(
          invokeProxy: ({required imageUrl}) async => response,
        );

        await expectLater(
          adapter.analyze(_input()),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('Unexpected Kindwise plant-health proxy response shape'),
            ),
          ),
        );
      }
    },
  );

  test('propagates the identical proxy failure object', () async {
    final proxyError = StateError('proxy failed');
    final adapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async => throw proxyError,
    );

    await expectLater(adapter.analyze(_input()), throwsA(same(proxyError)));
  });

  test('lets parser handle malformed Kindwise health payload safely', () async {
    final adapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async => {
        'result': {
          'is_healthy': {'binary': 'false'},
          'disease': {
            'suggestions': [
              {
                'id': 'fake-actionable',
                'name': 'Insecta',
                'probability': 0.97,
                'details': {
                  'local_name': '해충 피해',
                  'classification': ['Animalia', 'Insecta'],
                  'common_names': ['pest'],
                },
              },
            ],
          },
        },
      },
    );

    final result = await adapter.analyze(_input());

    expect(result.conditionEventHints, hasLength(1));
    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.conditionUncertain,
    );
  });

  test('preserves requestedAt fallback through adapter', () async {
    final requestedAt = DateTime.utc(2026, 6, 22, 4, 5, 6);
    final adapter = KindwisePlantHealthAdapter(
      invokeProxy: ({required imageUrl}) async => {
        'created': 'not-a-timestamp',
        'result': {
          'is_healthy': {'binary': true, 'probability': 0.94},
        },
      },
    );

    final result = await adapter.analyze(_input(requestedAt: requestedAt));

    expect(result.createdAt, requestedAt);
  });
}

String _fixture(String name) {
  return File('test/fixtures/kindwise/$name').readAsStringSync();
}

Map<String, dynamic> _healthyFixtureMap() {
  return Map<String, dynamic>.from(
    jsonDecode(_fixture('health_healthy_response.json')) as Map,
  );
}

PlantAnalysisInput _input({
  String analysisType = PlantAnalysisTypes.conditionCheck,
  String? imageUrl = 'https://example.test/photo.jpg',
  DateTime? requestedAt,
}) {
  return PlantAnalysisInput(
    plantId: 'test-plant',
    analysisType: analysisType,
    imageUrl: imageUrl,
    requestedAt: requestedAt ?? DateTime.utc(2026, 6, 22),
  );
}
