import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/gemini_default_state_observation_parser.dart';
import 'package:plantalk2/plant_analysis/adapters/plant_analysis_adapter.dart';
import 'package:plantalk2/plant_analysis/bridges/condition_check_memory_payload_bridge.dart';
import 'package:plantalk2/plant_analysis/models/external_plant_analysis_result.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/plant_analysis/selectors/plant_condition_representative_event_selector.dart';
import 'package:plantalk2/plant_analysis/services/plant_analysis_service.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';

void main() {
  const parser = GeminiDefaultStateObservationParser();

  test('maps stable appearance without trusting model prose or confidence', () {
    final result = parser.resultFromMap({
      'observation_id': '  observation-1  ',
      'observed_at': '2026-06-24T01:02:03Z',
      'image_quality': 'usable',
      'observation_state': 'stable_appearance',
      'evidence_tags': ['stable_foliage'],
      'summary_ko': '이 식물은 완벽하게 건강합니다.',
      'diagnosis': '확정 진단',
      'recommended_action': '약제를 사용하세요.',
      'confidence': 0.99,
    }, _input());

    expect(result.providerKey, GeminiDefaultStateObservationParser.providerKey);
    expect(result.analysisType, PlantAnalysisTypes.defaultObservation);
    expect(result.providerResultId, 'observation-1');
    expect(result.createdAt, DateTime.utc(2026, 6, 24, 1, 2, 3));
    expect(result.rawPayload, isEmpty);
    expect(result.isMock, isFalse);
    expect(result.conditionEventHints, hasLength(1));

    final hint = result.conditionEventHints.single;
    expect(hint.eventType, PlantAnalysisEventTypes.appearanceStable);
    expect(hint.confidence, isNull);
    expect(hint.note, '사진에서 겉으로 보이는 상태가 비교적 안정적으로 보여요. 건강 진단 결과는 아니에요.');
    expect(result.summary, hint.note);
    expect(result.summary, isNot(contains('완벽하게 건강')));
    expect(result.summary, isNot(contains('확정 진단')));
    expect(result.summary, isNot(contains('약제')));
  });

  test('maps positive observations only when matching evidence is present', () {
    const cases = [
      (
        state: GeminiDefaultObservationStates.growthPositive,
        evidence: GeminiDefaultObservationEvidenceTags.newGrowth,
        eventType: PlantAnalysisEventTypes.growthPositive,
      ),
      (
        state: GeminiDefaultObservationStates.newLeafObserved,
        evidence: GeminiDefaultObservationEvidenceTags.newLeaf,
        eventType: PlantAnalysisEventTypes.newLeafObserved,
      ),
      (
        state: GeminiDefaultObservationStates.floweringObserved,
        evidence: GeminiDefaultObservationEvidenceTags.flowering,
        eventType: PlantAnalysisEventTypes.floweringObserved,
      ),
    ];

    for (final testCase in cases) {
      final result = parser.resultFromMap({
        'image_quality': GeminiDefaultObservationImageQualities.usable,
        'observation_state': testCase.state,
        'evidence_tags': [testCase.evidence],
      }, _input());

      final hint = result.conditionEventHints.single;
      expect(hint.eventType, testCase.eventType);
      expect(hint.note, isNotEmpty);
      expect(hint.confidence, isNull);
    }
  });

  test('concern evidence overrides a claimed positive observation', () {
    final result = parser.resultFromMap({
      'image_quality': 'usable',
      'observation_state': 'new_leaf_observed',
      'evidence_tags': ['new_leaf', 'visible_discoloration'],
    }, _input());

    final hint = result.conditionEventHints.single;
    expect(hint.eventType, PlantAnalysisEventTypes.conditionUncertain);
    expect(hint.note, contains('별도 건강 확인'));
    _expectNoDiagnosticOrActionableEvent(hint.eventType);
  });

  test('falls back to uncertainty for weak or inconsistent output', () {
    const payloads = <Map<String, Object?>>[
      {
        'image_quality': 'limited',
        'observation_state': 'stable_appearance',
        'evidence_tags': ['stable_foliage'],
      },
      {
        'image_quality': 'unusable',
        'observation_state': 'new_leaf_observed',
        'evidence_tags': ['new_leaf'],
      },
      {
        'image_quality': 'usable',
        'observation_state': 'growth_positive',
        'evidence_tags': ['stable_foliage'],
      },
      {
        'image_quality': 'usable',
        'observation_state': 'visible_concern',
        'evidence_tags': <String>[],
      },
      {
        'image_quality': 'usable',
        'observation_state': 'unknown_state',
        'evidence_tags': ['stable_foliage'],
      },
      {
        'image_quality': 'usable',
        'observation_state': 'stable_appearance',
        'evidence_tags': ['stable_foliage', 'unapproved_model_tag'],
      },
      {
        'image_quality': 'usable',
        'observation_state': 'stable_appearance',
        'evidence_tags': ['stable_foliage', 42],
      },
      {
        'observation_state': 'stable_appearance',
        'evidence_tags': ['stable_foliage'],
      },
    ];

    for (final payload in payloads) {
      final result = parser.resultFromMap(payload, _input());
      final hint = result.conditionEventHints.single;

      expect(hint.eventType, PlantAnalysisEventTypes.conditionUncertain);
      expect(hint.confidence, isNull);
      _expectNoDiagnosticOrActionableEvent(hint.eventType);
    }
  });

  test('supports JSON input and rejects a non-object JSON response', () {
    final result = parser.resultFromJson(
      jsonEncode({
        'image_quality': 'usable',
        'observation_state': 'flowering_observed',
        'evidence_tags': ['flowering'],
      }),
      _input(),
    );

    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.floweringObserved,
    );
    expect(
      () => parser.resultFromJson('[]', _input()),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'rejects condition-check input to keep Gemini out of diagnosis flow',
    () {
      expect(
        () => parser.resultFromMap({
          'image_quality': 'usable',
          'observation_state': 'stable_appearance',
          'evidence_tags': ['stable_foliage'],
        }, _input(analysisType: PlantAnalysisTypes.conditionCheck)),
        throwsA(isA<UnsupportedError>()),
      );
    },
  );

  test('uses requestedAt when observed_at is missing or invalid', () {
    final requestedAt = DateTime.utc(2026, 6, 24, 3, 4, 5);
    final result = parser.resultFromMap({
      'observed_at': 'not-a-date',
      'image_quality': 'usable',
      'observation_state': 'stable_appearance',
      'evidence_tags': ['stable_foliage'],
    }, _input(requestedAt: requestedAt));

    expect(result.createdAt, requestedAt);
  });

  test(
    'uncertainty outranks appearance_stable in representative selection',
    () {
      const selector = PlantConditionRepresentativeEventSelector();
      const stable = NormalizedPlantEvent(
        eventType: PlantAnalysisEventTypes.appearanceStable,
        sourceProvider: GeminiDefaultStateObservationParser.providerKey,
      );
      const uncertain = NormalizedPlantEvent(
        eventType: PlantAnalysisEventTypes.conditionUncertain,
        sourceProvider: GeminiDefaultStateObservationParser.providerKey,
      );

      expect(selector.select([stable, uncertain]), same(uncertain));
    },
  );

  test(
    'appearance_stable fallback remains explicitly non-diagnostic',
    () async {
      const externalResult = ExternalPlantAnalysisResult(
        providerKey: GeminiDefaultStateObservationParser.providerKey,
        analysisType: PlantAnalysisTypes.defaultObservation,
        conditionEventHints: [
          ExternalPlantConditionEventHint(
            eventType: PlantAnalysisEventTypes.appearanceStable,
          ),
        ],
      );
      const conditionService = MockPlantConditionAnalysisService(
        plantAnalysisService: PlantAnalysisService(
          adapter: _ResultAdapter(externalResult),
        ),
      );

      final conditionResult = await conditionService.analyzeCondition(
        const PlantConditionAnalysisRequest(
          plantId: 'plant-1',
          photoUrl: 'https://example.test/photo.jpg',
        ),
      );

      expect(
        conditionResult.conditionEventType,
        PlantConditionEventTypes.normal,
      );
      expect(conditionResult.conditionMessage, contains('건강 진단 결과는 아니에요'));
      expect(conditionResult.conditionMessage, isNot(contains('큰 이상이 없어 보여요')));
    },
  );

  test(
    'appearance_stable remains non-diagnostic through shared mapping',
    () async {
      final externalResult = parser.resultFromMap({
        'image_quality': 'usable',
        'observation_state': 'stable_appearance',
        'evidence_tags': ['stable_foliage'],
      }, _input());
      final conditionService = MockPlantConditionAnalysisService(
        plantAnalysisService: PlantAnalysisService(
          adapter: _ResultAdapter(externalResult),
        ),
      );

      final conditionResult = await conditionService.analyzeCondition(
        const PlantConditionAnalysisRequest(
          plantId: 'plant-1',
          photoUrl: 'https://example.test/photo.jpg',
        ),
      );

      expect(
        conditionResult.conditionEventType,
        PlantConditionEventTypes.normal,
      );
      expect(
        conditionResult.normalizedEvent.eventType,
        PlantAnalysisEventTypes.appearanceStable,
      );
      expect(conditionResult.conditionMessage, contains('건강 진단 결과는 아니에요'));
      expect(conditionResult.conditionMessage, isNot(contains('큰 이상이 없어 보여요')));
      expect(conditionResult.normalizedEvent.metadata, {
        'analysisType': PlantAnalysisTypes.defaultObservation,
      });
    },
  );

  test('appearance_stable memory fallback remains non-diagnostic', () {
    const bridge = ConditionCheckMemoryPayloadBridge();
    final payload = bridge.fromNormalizedEvent(
      event: const NormalizedPlantEvent(
        eventType: PlantAnalysisEventTypes.appearanceStable,
        sourceProvider: GeminiDefaultStateObservationParser.providerKey,
      ),
      plantId: 'plant-1',
      photoUrl: 'https://example.test/photo.jpg',
    );

    expect(payload.eventType, PlantConditionEventTypes.normal);
    expect(payload.message, contains('건강 진단 결과는 아니에요'));
    expect(payload.message, isNot(contains('큰 이상이 없어 보여요')));
  });
}

PlantAnalysisInput _input({
  String analysisType = PlantAnalysisTypes.defaultObservation,
  DateTime? requestedAt,
}) {
  return PlantAnalysisInput(
    plantId: 'plant-1',
    analysisType: analysisType,
    imageUrl: 'https://example.test/photo.jpg',
    requestedAt: requestedAt ?? DateTime.utc(2026, 6, 24),
  );
}

void _expectNoDiagnosticOrActionableEvent(String eventType) {
  const diagnosticOrActionableEvents = <String>{
    PlantAnalysisEventTypes.waterNeeded,
    PlantAnalysisEventTypes.overwaterSuspected,
    PlantAnalysisEventTypes.lightNeeded,
    PlantAnalysisEventTypes.tooMuchSunSuspected,
    PlantAnalysisEventTypes.pestSuspected,
    PlantAnalysisEventTypes.diseaseSuspected,
    PlantAnalysisEventTypes.repottingSuggested,
    PlantAnalysisEventTypes.soilCheckNeeded,
    PlantAnalysisEventTypes.temperatureStressSuspected,
    PlantAnalysisEventTypes.humidityIssueSuspected,
  };

  expect(diagnosticOrActionableEvents.contains(eventType), isFalse);
}

class _ResultAdapter implements PlantAnalysisAdapter {
  const _ResultAdapter(this.result);

  final ExternalPlantAnalysisResult result;

  @override
  String get providerKey => result.providerKey;

  @override
  Future<ExternalPlantAnalysisResult> analyze(PlantAnalysisInput input) async {
    return result;
  }
}
