import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/gemini_default_state_observation_adapter.dart';
import 'package:plantalk2/plant_analysis/adapters/gemini_default_state_observation_parser.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/plant_analysis/services/plant_analysis_service.dart';

void main() {
  test('providerKey identifies Gemini default observation', () {
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async => _stablePayload(),
    );

    expect(
      adapter.providerKey,
      GeminiDefaultStateObservationParser.providerKey,
    );
  });

  test('parses direct map response after trimming imageUrl', () async {
    var callCount = 0;
    String? receivedImageUrl;
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async {
        callCount += 1;
        receivedImageUrl = imageUrl;
        return _stablePayload();
      },
    );

    final result = await adapter.analyze(
      _input(imageUrl: '  https://example.test/condition-photo.jpg  '),
    );

    expect(callCount, 1);
    expect(receivedImageUrl, 'https://example.test/condition-photo.jpg');
    expect(result.providerKey, GeminiDefaultStateObservationParser.providerKey);
    expect(result.analysisType, PlantAnalysisTypes.defaultObservation);
    expect(result.rawPayload, isEmpty);
    expect(result.conditionEventHints, hasLength(1));
    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.appearanceStable,
    );
    expect(result.conditionEventHints.single.confidence, isNull);
  });

  test('parses JSON string response', () async {
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async => jsonEncode({
        'image_quality': 'usable',
        'observation_state': 'new_leaf_observed',
        'evidence_tags': ['new_leaf'],
      }),
    );

    final result = await adapter.analyze(_input());

    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.newLeafObserved,
    );
  });

  test(
    'works through PlantAnalysisService without changing normalized events',
    () async {
      final service = PlantAnalysisService(
        adapter: GeminiDefaultStateObservationAdapter(
          invokeProxy: ({required imageUrl}) async => _stablePayload(),
        ),
      );

      final result = await service.analyze(_input());

      expect(
        result.externalResult.providerKey,
        GeminiDefaultStateObservationParser.providerKey,
      );
      expect(result.externalResult.conditionEventHints, hasLength(1));
      expect(result.normalizedEvents, hasLength(1));

      final event = result.normalizedEvents.single;
      expect(event.eventType, PlantAnalysisEventTypes.appearanceStable);
      expect(event.message, contains('건강 진단 결과는 아니에요'));
      expect(event.confidence, isNull);
      expect(event.metadata, {
        'analysisType': PlantAnalysisTypes.defaultObservation,
      });
    },
  );

  test('proxy callback contract exposes only imageUrl', () async {
    var callCount = 0;
    String? receivedImageUrl;
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async {
        callCount += 1;
        receivedImageUrl = imageUrl;
        return _stablePayload();
      },
    );

    await adapter.analyze(
      PlantAnalysisInput(
        plantId: 'private-plant-id',
        analysisType: PlantAnalysisTypes.defaultObservation,
        speciesKey: 'private-species-key',
        speciesDisplayName: 'Private plant',
        imagePath: r'C:\private\photo.jpg',
        imageUrl: 'https://example.test/private-photo.jpg',
        userPrompt: 'private prompt',
        requestedAt: DateTime.utc(2026, 6, 24, 1, 2, 3),
        metadata: const {'private': 'metadata'},
      ),
    );

    expect(callCount, 1);
    expect(receivedImageUrl, 'https://example.test/private-photo.jpg');
  });

  test('rejects unsupported analysis types without invoking proxy', () async {
    for (final analysisType in const [
      PlantAnalysisTypes.conditionCheck,
      PlantAnalysisTypes.identification,
      PlantAnalysisTypes.combined,
      'unknown_analysis',
    ]) {
      var callCount = 0;
      final adapter = GeminiDefaultStateObservationAdapter(
        invokeProxy: ({required imageUrl}) async {
          callCount += 1;
          return _stablePayload();
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
      final adapter = GeminiDefaultStateObservationAdapter(
        invokeProxy: ({required imageUrl}) async {
          callCount += 1;
          return _stablePayload();
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
      final adapter = GeminiDefaultStateObservationAdapter(
        invokeProxy: ({required imageUrl}) async {
          callCount += 1;
          return _stablePayload();
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
      final adapter = GeminiDefaultStateObservationAdapter(
        invokeProxy: ({required imageUrl}) async {
          receivedImageUrl = imageUrl;
          return _stablePayload();
        },
      );

      await adapter.analyze(_input(imageUrl: '  $imageUrl  '));

      expect(receivedImageUrl, imageUrl);
    }
  });

  test('parses supported response map forms', () async {
    final mapStringDynamicAdapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async => _stablePayload(),
    );
    final mapObjectAdapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async =>
          Map<Object?, Object?>.from(_stablePayload()),
    );

    final directResult = await mapStringDynamicAdapter.analyze(_input());
    final convertedResult = await mapObjectAdapter.analyze(_input());

    expect(
      directResult.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.appearanceStable,
    );
    expect(
      convertedResult.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.appearanceStable,
    );
  });

  test('throws FormatException for unsupported proxy response shapes', () async {
    for (final response in const [null, [], 42, true]) {
      final adapter = GeminiDefaultStateObservationAdapter(
        invokeProxy: ({required imageUrl}) async => response,
      );

      await expectLater(
        adapter.analyze(_input()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'Unexpected Gemini default-state observation proxy response shape',
            ),
          ),
        ),
      );
    }
  });

  test('propagates the identical proxy failure object', () async {
    final proxyError = StateError('proxy failed');
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async => throw proxyError,
    );

    await expectLater(adapter.analyze(_input()), throwsA(same(proxyError)));
  });

  test('lets parser degrade malformed gateway payload safely', () async {
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async => {
        'image_quality': 'usable',
        'observation_state': 'stable_appearance',
        'evidence_tags': ['stable_foliage', 'unapproved_model_tag'],
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
    final requestedAt = DateTime.utc(2026, 6, 24, 4, 5, 6);
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: ({required imageUrl}) async => {
        'observed_at': 'not-a-timestamp',
        'image_quality': 'usable',
        'observation_state': 'stable_appearance',
        'evidence_tags': ['stable_foliage'],
      },
    );

    final result = await adapter.analyze(_input(requestedAt: requestedAt));

    expect(result.createdAt, requestedAt);
  });
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
  String? imageUrl = 'https://example.test/photo.jpg',
  DateTime? requestedAt,
}) {
  return PlantAnalysisInput(
    plantId: 'test-plant',
    analysisType: analysisType,
    imageUrl: imageUrl,
    requestedAt: requestedAt ?? DateTime.utc(2026, 6, 24),
  );
}
