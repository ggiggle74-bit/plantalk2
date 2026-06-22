import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/kindwise_plant_health_response_parser.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/plant_analysis/normalizers/plant_analysis_normalizer.dart';
import 'package:plantalk2/plant_analysis/selectors/plant_condition_representative_event_selector.dart';

void main() {
  const parser = KindwisePlantHealthResponseParser();

  test(
    'healthy fixture emits one health_ok event and ignores disease suggestions',
    () {
      final result = parser.resultFromJson(
        _fixture('health_healthy_response.json'),
        _input(),
      );

      expect(result.providerKey, KindwisePlantHealthResponseParser.providerKey);
      expect(result.analysisType, PlantAnalysisTypes.conditionCheck);
      expect(result.providerResultId, 'fake-kindwise-health-healthy-token');
      expect(
        result.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1782057600000, isUtc: true),
      );
      expect(result.isMock, isFalse);
      expect(result.rawPayload, isEmpty);
      expect(result.speciesSuggestions, isEmpty);
      expect(result.conditionEventHints, hasLength(1));

      final hint = result.conditionEventHints.single;
      expect(hint.eventType, PlantAnalysisEventTypes.healthOk);
      expect(hint.confidence, 0.94);
      expect(hint.note, isNull);
    },
  );

  test(
    'mixed unhealthy fixture preserves provider order and keeps first three mapped hints',
    () {
      final result = parser.resultFromJson(
        _fixture('health_unhealthy_mixed_response.json'),
        _input(),
      );

      expect(result.conditionEventHints, hasLength(3));
      expect(result.conditionEventHints.map((hint) => hint.eventType), [
        PlantAnalysisEventTypes.pestSuspected,
        PlantAnalysisEventTypes.overwaterSuspected,
        PlantAnalysisEventTypes.diseaseSuspected,
      ]);
      expect(result.conditionEventHints.map((hint) => hint.confidence), [
        0.72,
        0.64,
        0.55,
      ]);
      expect(result.conditionEventHints.map((hint) => hint.note), [
        '사진에서 해충 피해 관련 신호가 있을 수 있어요.',
        '사진에서 과습 또는 불균형한 물주기 관련 신호가 있을 수 있어요.',
        '사진에서 곰팡이성 질환 관련 신호가 있을 수 있어요.',
      ]);
      expect(
        result.conditionEventHints.map((hint) => hint.eventType),
        isNot(contains(PlantAnalysisEventTypes.lightNeeded)),
      );

      final retainedText = [
        ?result.summary,
        ...result.rawPayload.values.map((value) => '$value'),
        ...result.conditionEventHints.map((hint) => '${hint.note}'),
      ].join('\n');
      expect(retainedText, isNot(contains('ignored-description')));
      expect(retainedText, isNot(contains('ignored-treatment')));
    },
  );

  test('unmapped unhealthy fixture emits one condition_uncertain event', () {
    final result = parser.resultFromJson(
      _fixture('health_unhealthy_unmapped_response.json'),
      _input(),
    );

    expect(result.conditionEventHints, hasLength(1));
    final hint = result.conditionEventHints.single;
    expect(hint.eventType, PlantAnalysisEventTypes.conditionUncertain);
    expect(hint.confidence, isNull);
    expect(hint.note, isNull);
  });

  test(
    'malformed healthy gate fixture emits uncertainty and ignores actionable suggestion',
    () {
      final result = parser.resultFromJson(
        _fixture('health_malformed_response.json'),
        _input(),
      );

      expect(result.conditionEventHints, hasLength(1));
      final hint = result.conditionEventHints.single;
      expect(hint.eventType, PlantAnalysisEventTypes.conditionUncertain);
      expect(hint.eventType, isNot(PlantAnalysisEventTypes.pestSuspected));
      expect(hint.confidence, isNull);
      expect(hint.note, isNull);
    },
  );

  test('maps recognized suggestion evidence conservatively', () {
    final cases = <String, String>{
      'water deficiency': PlantAnalysisEventTypes.waterNeeded,
      'water excess': PlantAnalysisEventTypes.overwaterSuspected,
      'insufficient light': PlantAnalysisEventTypes.lightNeeded,
      'sunburn': PlantAnalysisEventTypes.tooMuchSunSuspected,
      'Insecta': PlantAnalysisEventTypes.pestSuspected,
      'Animalia': PlantAnalysisEventTypes.pestSuspected,
      'Fungi': PlantAnalysisEventTypes.diseaseSuspected,
      'nutrient deficiency': PlantAnalysisEventTypes.soilCheckNeeded,
      'root bound': PlantAnalysisEventTypes.repottingSuggested,
      'frost damage': PlantAnalysisEventTypes.temperatureStressSuspected,
      'humidity stress': PlantAnalysisEventTypes.humidityIssueSuspected,
      'new leaf observed': PlantAnalysisEventTypes.newLeafObserved,
      'flowering observed': PlantAnalysisEventTypes.floweringObserved,
      'positive growth': PlantAnalysisEventTypes.growthPositive,
    };

    for (final entry in cases.entries) {
      final result = parser.resultFromMap(
        _responseWithSuggestions([
          _suggestion(name: 'unsupported parent', classification: [entry.key]),
        ]),
        _input(),
      );

      expect(
        result.conditionEventHints.single.eventType,
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('leaves unsupported suggestion evidence unmapped', () {
    for (final evidence in const [
      'mechanical damage',
      'generic abiotic',
      'senescence',
      'finished flowering period',
      'generic water-related issue',
    ]) {
      final result = parser.resultFromMap(
        _responseWithSuggestions([
          _suggestion(name: evidence, classification: [evidence]),
        ]),
        _input(),
      );

      expect(
        result.conditionEventHints.single.eventType,
        PlantAnalysisEventTypes.conditionUncertain,
        reason: evidence,
      );
      expect(result.conditionEventHints.single.confidence, isNull);
      expect(result.conditionEventHints.single.note, isNull);
    }
  });

  test('parses, clamps, and nulls confidence values', () {
    final cases = <Object?, double?>{
      '0.42': 0.42,
      -0.1: 0,
      1.4: 1,
      'not-a-number': null,
    };

    for (final entry in cases.entries) {
      final result = parser.resultFromMap(
        _responseWithSuggestions([
          _suggestion(name: 'water deficiency', probability: entry.key),
        ]),
        _input(),
      );

      expect(result.conditionEventHints.single.confidence, entry.value);
    }
  });

  test('parses fractional epoch seconds as UTC', () {
    final result = parser.resultFromMap(
      _responseWithSuggestions([
        _suggestion(name: 'water deficiency'),
      ], created: 1782057600.25),
      _input(),
    );

    expect(
      result.createdAt,
      DateTime.fromMillisecondsSinceEpoch(1782057600250, isUtc: true),
    );
  });

  test('falls back to input requestedAt when created is malformed', () {
    final requestedAt = DateTime.utc(2026, 6, 22, 1, 2, 3);
    final result = parser.resultFromMap(
      _responseWithSuggestions([
        _suggestion(name: 'water deficiency'),
      ], created: 'not-a-date'),
      _input(requestedAt: requestedAt),
    );

    expect(result.createdAt, requestedAt);
  });

  test('throws FormatException for JSON top-level list', () {
    expect(
      () => parser.resultFromJson('[]', _input()),
      throwsA(isA<FormatException>()),
    );
  });

  test('malformed health map emits uncertainty without throwing', () {
    final result = parser.resultFromMap({
      'result': {
        'is_healthy': {'binary': null},
        'disease': {
          'suggestions': [_suggestion(name: 'Insecta', probability: 0.99)],
        },
      },
    }, _input());

    expect(result.conditionEventHints, hasLength(1));
    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.conditionUncertain,
    );
  });

  test(
    'parsed unhealthy result normalizes and selects pest event with confidence and note',
    () {
      const normalizer = PlantAnalysisNormalizer();
      const selector = PlantConditionRepresentativeEventSelector();

      final result = parser.resultFromJson(
        _fixture('health_unhealthy_mixed_response.json'),
        _input(),
      );
      final selected = selector.select(normalizer.normalize(result));

      expect(selected.eventType, PlantAnalysisEventTypes.pestSuspected);
      expect(selected.confidence, 0.72);
      expect(selected.message, '사진에서 해충 피해 관련 신호가 있을 수 있어요.');
    },
  );
}

String _fixture(String name) {
  return File('test/fixtures/kindwise/$name').readAsStringSync();
}

PlantAnalysisInput _input({DateTime? requestedAt}) {
  return PlantAnalysisInput(
    plantId: 'test-plant',
    analysisType: PlantAnalysisTypes.conditionCheck,
    requestedAt: requestedAt ?? DateTime.utc(2026, 6, 22),
  );
}

Map<String, dynamic> _responseWithSuggestions(
  List<Map<String, dynamic>> suggestions, {
  Object? created = 1782057600,
}) {
  return {
    'access_token': 'fake-inline-token',
    'created': created,
    'result': {
      'is_healthy': {'binary': false, 'probability': 0.20, 'threshold': 0.63},
      'disease': {'suggestions': suggestions},
    },
  };
}

Map<String, dynamic> _suggestion({
  required String name,
  Object? probability = 0.5,
  List<String> classification = const [],
  String? localName,
  List<String> commonNames = const [],
}) {
  return {
    'id': 'fake-inline-candidate',
    'name': name,
    'probability': probability,
    'details': {
      'local_name': localName,
      'classification': classification,
      'common_names': commonNames,
    },
  };
}
