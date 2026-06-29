import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plantalk2/plant_analysis/bridges/condition_check_memory_payload_bridge.dart';
import 'package:plantalk2/plant_analysis/factories/gemini_default_observation_service_factory.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';
import 'package:plantalk2/services/plant_condition_check_flow_service.dart';

void main() {
  test('runs photo, analysis, memory, then returns the flow result', () async {
    final image = _image();
    final analysisResult = _analysisResult();
    final events = <String>[];
    XFile? savedImage;
    String? savedPlantId;
    PlantConditionAnalysisRequest? analysisRequest;
    ConditionCheckMemoryPayload? memoryPayload;

    final service = PlantConditionCheckFlowService.withCallbacks(
      saveConditionCheckPhoto: ({required image, required plantId}) async {
        events.add('photo');
        savedImage = image;
        savedPlantId = plantId;
        return _remotePhotoUrl;
      },
      analyzeCondition: (request) async {
        events.add('analysis');
        analysisRequest = request;
        return analysisResult;
      },
      insertConditionCheckMemory: (payload) async {
        events.add('memory');
        memoryPayload = payload;
      },
    );

    final result = await service.checkCondition(
      image: image,
      plantId: _plantId,
      speciesKey: _speciesKey,
      speciesDisplayName: _speciesDisplayName,
    );

    expect(events, ['photo', 'analysis', 'memory']);
    expect(savedImage, same(image));
    expect(savedPlantId, _plantId);
    expect(analysisRequest?.plantId, _plantId);
    expect(analysisRequest?.photoUrl, _remotePhotoUrl);
    expect(analysisRequest?.speciesKey, _speciesKey);
    expect(analysisRequest?.speciesDisplayName, _speciesDisplayName);
    expect(memoryPayload?.plantId, _plantId);
    expect(
      memoryPayload?.memoryType,
      ConditionCheckMemoryPayloadBridge.conditionCheckMemoryType,
    );
    expect(memoryPayload?.eventType, PlantConditionEventTypes.pestRisk);
    expect(memoryPayload?.message, _providerMessage);
    expect(memoryPayload?.photoUrl, _remotePhotoUrl);
    expect(memoryPayload?.isMock, isFalse);
    expect(result.photoUrl, _remotePhotoUrl);
    expect(result.analysisResult, same(analysisResult));
    expect(result.memoryPayload, same(memoryPayload));
    expect(result.memoryPayload.plantId, _plantId);
    expect(
      result.memoryPayload.memoryType,
      ConditionCheckMemoryPayloadBridge.conditionCheckMemoryType,
    );
    expect(result.memoryPayload.eventType, PlantConditionEventTypes.pestRisk);
    expect(result.memoryPayload.message, _providerMessage);
    expect(result.memoryPayload.photoUrl, _remotePhotoUrl);
    expect(result.memoryPayload.isMock, isFalse);
  });

  test('awaits memory insertion before completing', () async {
    final memoryCompleter = Completer<void>();
    final analysisResult = _analysisResult();

    final service = PlantConditionCheckFlowService.withCallbacks(
      saveConditionCheckPhoto: ({required image, required plantId}) async {
        return _remotePhotoUrl;
      },
      analyzeCondition: (request) async {
        return analysisResult;
      },
      insertConditionCheckMemory: (payload) {
        return memoryCompleter.future;
      },
    );

    var completed = false;
    final flowFuture = service
        .checkCondition(image: _image(), plantId: _plantId)
        .then((_) {
          completed = true;
        });

    await Future<void>.delayed(Duration.zero);

    expect(completed, isFalse);

    memoryCompleter.complete();
    await flowFuture;

    expect(completed, isTrue);
  });

  test('photo-storage failure stops downstream work and propagates', () async {
    final error = StateError('photo failed');
    var analysisCalled = false;
    var memoryCalled = false;

    final service = PlantConditionCheckFlowService.withCallbacks(
      saveConditionCheckPhoto: ({required image, required plantId}) async {
        throw error;
      },
      analyzeCondition: (request) async {
        analysisCalled = true;
        return _analysisResult();
      },
      insertConditionCheckMemory: (payload) async {
        memoryCalled = true;
      },
    );

    await expectLater(
      service.checkCondition(image: _image(), plantId: _plantId),
      throwsA(same(error)),
    );
    expect(analysisCalled, isFalse);
    expect(memoryCalled, isFalse);
  });

  test('analysis failure stops memory persistence and propagates', () async {
    final error = StateError('analysis failed');
    var memoryCalled = false;

    final service = PlantConditionCheckFlowService.withCallbacks(
      saveConditionCheckPhoto: ({required image, required plantId}) async {
        return _remotePhotoUrl;
      },
      analyzeCondition: (request) async {
        throw error;
      },
      insertConditionCheckMemory: (payload) async {
        memoryCalled = true;
      },
    );

    await expectLater(
      service.checkCondition(image: _image(), plantId: _plantId),
      throwsA(same(error)),
    );
    expect(memoryCalled, isFalse);
  });

  test('forwards nullable species identity unchanged', () async {
    PlantConditionAnalysisRequest? analysisRequest;

    final service = PlantConditionCheckFlowService.withCallbacks(
      saveConditionCheckPhoto: ({required image, required plantId}) async {
        return _remotePhotoUrl;
      },
      analyzeCondition: (request) async {
        analysisRequest = request;
        return _analysisResult();
      },
      insertConditionCheckMemory: (payload) async {},
    );

    await service.checkCondition(image: _image(), plantId: _plantId);

    expect(analysisRequest?.speciesKey, isNull);
    expect(analysisRequest?.speciesDisplayName, isNull);
  });

  test(
    'uses fake Gemini-backed default observation and preserves memory',
    () async {
      String? receivedImageUrl;
      ConditionCheckMemoryPayload? memoryPayload;
      final conditionAnalysisService = MockPlantConditionAnalysisService(
        plantAnalysisService:
            GeminiDefaultObservationServiceFactory.withProxyCallback(
              invokeProxy: ({required imageUrl}) async {
                receivedImageUrl = imageUrl;
                return _geminiStablePayload();
              },
            ).build(),
        analysisType: PlantAnalysisTypes.defaultObservation,
      );

      final service = PlantConditionCheckFlowService.withCallbacks(
        saveConditionCheckPhoto: ({required image, required plantId}) async {
          return _remotePhotoUrl;
        },
        analyzeCondition: conditionAnalysisService.analyzeCondition,
        insertConditionCheckMemory: (payload) async {
          memoryPayload = payload;
        },
      );

      final result = await service.checkCondition(
        image: _image(),
        plantId: _plantId,
        speciesKey: _speciesKey,
        speciesDisplayName: _speciesDisplayName,
      );

      expect(receivedImageUrl, _remotePhotoUrl);
      expect(result.photoUrl, _remotePhotoUrl);
      expect(result.analysisResult.isMock, isFalse);
      expect(result.analysisResult.normalizedEvent.isMock, isFalse);
      expect(result.memoryPayload, same(memoryPayload));
      expect(
        result.memoryPayload.memoryType,
        ConditionCheckMemoryPayloadBridge.conditionCheckMemoryType,
      );
      expect(result.memoryPayload.photoUrl, _remotePhotoUrl);
      expect(result.memoryPayload.isMock, isFalse);
    },
  );

  test(
    'falls back explicitly to mock condition analysis when Gemini fails',
    () async {
      final backendError = StateError('gemini failed');
      final logs = <Object>[];
      ConditionCheckMemoryPayload? memoryPayload;
      final primary = MockPlantConditionAnalysisService(
        plantAnalysisService:
            GeminiDefaultObservationServiceFactory.withProxyCallback(
              invokeProxy: ({required imageUrl}) async {
                throw backendError;
              },
            ).build(),
        analysisType: PlantAnalysisTypes.defaultObservation,
      );
      final conditionAnalysisService = FallbackPlantConditionAnalysisService(
        primary: primary,
        fallback: const MockPlantConditionAnalysisService(),
        onPrimaryFailure: (error, stackTrace) {
          logs.add(error);
          logs.add(stackTrace);
        },
      );

      final service = PlantConditionCheckFlowService.withCallbacks(
        saveConditionCheckPhoto: ({required image, required plantId}) async {
          return _remotePhotoUrl;
        },
        analyzeCondition: conditionAnalysisService.analyzeCondition,
        insertConditionCheckMemory: (payload) async {
          memoryPayload = payload;
        },
      );

      final result = await service.checkCondition(
        image: _image(),
        plantId: _plantId,
      );

      expect(logs.first, same(backendError));
      expect(logs.last, isA<StackTrace>());
      expect(result.photoUrl, _remotePhotoUrl);
      expect(result.analysisResult.isMock, isTrue);
      expect(result.analysisResult.normalizedEvent.isMock, isTrue);
      expect(result.memoryPayload, same(memoryPayload));
      expect(
        result.memoryPayload.memoryType,
        ConditionCheckMemoryPayloadBridge.conditionCheckMemoryType,
      );
      expect(result.memoryPayload.photoUrl, _remotePhotoUrl);
      expect(result.memoryPayload.isMock, isTrue);
    },
  );
}

const _plantId = 'plant-1';
const _speciesKey = 'pothos';
const _speciesDisplayName = '스킨답서스';
const _remotePhotoUrl = 'https://example.test/condition-photo.jpg';
const _providerMessage = '잎 뒷면을 확인해야 할 수 있어요.';

XFile _image() {
  return XFile.fromData(
    Uint8List.fromList(const [1, 2, 3]),
    name: 'condition-photo.jpg',
    mimeType: 'image/jpeg',
  );
}

PlantConditionAnalysisResult _analysisResult() {
  const normalizedEvent = NormalizedPlantEvent(
    eventType: PlantAnalysisEventTypes.pestSuspected,
    sourceProvider: 'fake_provider',
    confidence: 0.72,
    message: _providerMessage,
    isMock: false,
    metadata: {'slot': 'condition'},
  );

  return const PlantConditionAnalysisResult(
    conditionEventType: PlantConditionEventTypes.pestRisk,
    conditionMessage: _providerMessage,
    normalizedEvent: normalizedEvent,
    isMock: false,
  );
}

Map<String, dynamic> _geminiStablePayload() {
  return {
    'observation_id': 'observation-1',
    'observed_at': '2026-06-24T01:02:03Z',
    'image_quality': 'usable',
    'observation_state': 'stable_appearance',
    'evidence_tags': ['stable_foliage'],
    'summary_ko': '사진에서 겉으로 보이는 상태가 비교적 안정적으로 보여요.',
  };
}
