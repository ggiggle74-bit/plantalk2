import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plantalk2/monetization/models/entitlement_check_context.dart';
import 'package:plantalk2/monetization/models/entitlement_check_result.dart';
import 'package:plantalk2/monetization/models/paid_feature.dart';
import 'package:plantalk2/plant_analysis/bridges/deep_health_assessment_memory_payload_bridge.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/services/deep_health_assessment_flow_service.dart';
import 'package:plantalk2/services/deep_health_assessment_gate_service.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';

void main() {
  test('blocked access stops photo, provider, and memory work', () async {
    final events = <String>[];
    final access = EntitlementCheckResult.paymentRequired(
      feature: PaidFeature.deepHealthAssessment,
      freeRemaining: 0,
    );
    final service = _service(
      events: events,
      access: access,
    );

    final outcome = await service.assess(
      image: _image(),
      plantId: _plantId,
    );

    expect(events, ['gate']);
    expect(outcome, isA<DeepHealthAssessmentBlockedOutcome>());
    expect(outcome.access, same(access));
    expect(outcome.isCompleted, isFalse);
  });

  test('allowed access runs gate, photo, analysis, and memory once', () async {
    final events = <String>[];
    const entitlementContext = EntitlementCheckContext(currentUsage: 1);
    EntitlementCheckContext? receivedContext;
    PlantConditionAnalysisRequest? receivedRequest;
    final access = EntitlementCheckResult.usageRemaining(
      feature: PaidFeature.deepHealthAssessment,
      freeRemaining: 1,
      currentUsage: 1,
    );
    final service = DeepHealthAssessmentFlowService(
      gateService: CallbackDeepHealthAssessmentGateService(
        authorizeAndReserve: ({required context}) async {
          events.add('gate');
          receivedContext = context;
          return access;
        },
      ),
      savePhoto: ({required image, required plantId}) async {
        events.add('photo');
        expect(plantId, _plantId);
        return _photoUrl;
      },
      analyze: (request) async {
        events.add('analysis');
        receivedRequest = request;
        return _analysisResult();
      },
      insertMemory: (payload) async {
        events.add('memory');
        expect(
          payload.memoryType,
          DeepHealthAssessmentMemoryPayloadBridge
              .deepHealthAssessmentMemoryType,
        );
      },
    );

    final outcome = await service.assess(
      image: _image(),
      plantId: _plantId,
      speciesKey: _speciesKey,
      speciesDisplayName: _speciesDisplayName,
      entitlementContext: entitlementContext,
    );

    expect(events, ['gate', 'photo', 'analysis', 'memory']);
    expect(receivedContext, same(entitlementContext));
    expect(receivedRequest?.plantId, _plantId);
    expect(receivedRequest?.photoUrl, _photoUrl);
    expect(receivedRequest?.speciesKey, _speciesKey);
    expect(receivedRequest?.speciesDisplayName, _speciesDisplayName);
    expect(outcome, isA<DeepHealthAssessmentCompletedOutcome>());

    final completed = outcome as DeepHealthAssessmentCompletedOutcome;
    expect(completed.access, same(access));
    expect(completed.photoUrl, _photoUrl);
    expect(completed.analysisResult.conditionMessage, _providerMessage);
    expect(
      completed.memoryPayload.memoryType,
      DeepHealthAssessmentMemoryPayloadBridge
          .deepHealthAssessmentMemoryType,
    );
    expect(completed.isCompleted, isTrue);
  });

  test('wrong-feature gate result fails before side effects', () async {
    final events = <String>[];
    final access = EntitlementCheckResult.allowed(
      feature: PaidFeature.plantCharacterSlot,
    );
    final service = _service(events: events, access: access);

    await expectLater(
      service.assess(image: _image(), plantId: _plantId),
      throwsStateError,
    );

    expect(events, ['gate']);
  });

  test('analysis failure stops memory persistence', () async {
    final events = <String>[];
    final error = StateError('analysis failed');
    var memoryCalled = false;
    final service = DeepHealthAssessmentFlowService(
      gateService: CallbackDeepHealthAssessmentGateService(
        authorizeAndReserve: ({required context}) async {
          events.add('gate');
          return EntitlementCheckResult.allowed(
            feature: PaidFeature.deepHealthAssessment,
          );
        },
      ),
      savePhoto: ({required image, required plantId}) async {
        events.add('photo');
        return _photoUrl;
      },
      analyze: (request) async {
        events.add('analysis');
        throw error;
      },
      insertMemory: (payload) async {
        memoryCalled = true;
      },
    );

    await expectLater(
      service.assess(image: _image(), plantId: _plantId),
      throwsA(same(error)),
    );

    expect(events, ['gate', 'photo', 'analysis']);
    expect(memoryCalled, isFalse);
  });

  test('awaits deep memory persistence before completing', () async {
    final memoryCompleter = Completer<void>();
    final events = <String>[];
    final service = DeepHealthAssessmentFlowService(
      gateService: CallbackDeepHealthAssessmentGateService(
        authorizeAndReserve: ({required context}) async {
          events.add('gate');
          return EntitlementCheckResult.allowed(
            feature: PaidFeature.deepHealthAssessment,
          );
        },
      ),
      savePhoto: ({required image, required plantId}) async {
        events.add('photo');
        return _photoUrl;
      },
      analyze: (request) async {
        events.add('analysis');
        return _analysisResult();
      },
      insertMemory: (payload) {
        events.add('memory');
        return memoryCompleter.future;
      },
    );

    var completed = false;
    final future = service
        .assess(image: _image(), plantId: _plantId)
        .then((_) => completed = true);

    await Future<void>.delayed(Duration.zero);

    expect(events, ['gate', 'photo', 'analysis', 'memory']);
    expect(completed, isFalse);

    memoryCompleter.complete();
    await future;

    expect(completed, isTrue);
  });
}

DeepHealthAssessmentFlowService _service({
  required List<String> events,
  required EntitlementCheckResult access,
}) {
  return DeepHealthAssessmentFlowService(
    gateService: CallbackDeepHealthAssessmentGateService(
      authorizeAndReserve: ({required context}) async {
        events.add('gate');
        return access;
      },
    ),
    savePhoto: ({required image, required plantId}) async {
      events.add('photo');
      return _photoUrl;
    },
    analyze: (request) async {
      events.add('analysis');
      return _analysisResult();
    },
    insertMemory: (payload) async {
      events.add('memory');
    },
  );
}

XFile _image() {
  return XFile.fromData(
    Uint8List.fromList(const [1, 2, 3]),
    name: 'deep-health.jpg',
    mimeType: 'image/jpeg',
  );
}

PlantConditionAnalysisResult _analysisResult() {
  const event = NormalizedPlantEvent(
    eventType: PlantAnalysisEventTypes.pestSuspected,
    sourceProvider: 'kindwise',
    confidence: 0.81,
    message: _providerMessage,
    sourceResultId: 'health-1',
  );

  return const PlantConditionAnalysisResult(
    conditionEventType: PlantConditionEventTypes.pestRisk,
    conditionMessage: _providerMessage,
    normalizedEvent: event,
  );
}

const _plantId = 'plant-1';
const _speciesKey = 'pothos';
const _speciesDisplayName = '스킨답서스';
const _photoUrl = 'https://example.test/deep-health.jpg';
const _providerMessage = '잎 뒷면에 해충 신호가 의심돼요.';
