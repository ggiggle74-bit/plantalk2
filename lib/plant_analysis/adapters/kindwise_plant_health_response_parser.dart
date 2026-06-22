import 'dart:convert';

import '../models/external_plant_analysis_result.dart';
import '../models/normalized_plant_event.dart';
import '../models/plant_analysis_input.dart';

class KindwisePlantHealthResponseParser {
  const KindwisePlantHealthResponseParser();

  static const providerKey = 'kindwise_plant_health';

  ExternalPlantAnalysisResult resultFromJson(
    String body,
    PlantAnalysisInput input,
  ) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException(
        'Unexpected Kindwise plant.health response shape.',
      );
    }

    return resultFromMap(Map<String, dynamic>.from(decoded), input);
  }

  ExternalPlantAnalysisResult resultFromMap(
    Map<String, dynamic> decoded,
    PlantAnalysisInput input,
  ) {
    return ExternalPlantAnalysisResult(
      providerKey: providerKey,
      analysisType: PlantAnalysisTypes.conditionCheck,
      providerResultId: _trimmedOrNull(decoded['access_token']),
      speciesSuggestions: const [],
      conditionEventHints: _conditionEventHints(decoded),
      rawPayload: const <String, Object?>{},
      isMock: false,
      createdAt: _createdAt(decoded['created'], input.requestedAt),
    );
  }

  List<ExternalPlantConditionEventHint> _conditionEventHints(
    Map<String, dynamic> decoded,
  ) {
    final result = _mapOrEmpty(decoded['result']);
    final isHealthy = _mapOrEmpty(result['is_healthy']);
    final binary = isHealthy['binary'];

    if (binary is! bool) {
      return const [_conditionUncertainHint];
    }

    if (binary) {
      return [
        ExternalPlantConditionEventHint(
          eventType: PlantAnalysisEventTypes.healthOk,
          confidence: _normalizedConfidence(isHealthy['probability']),
        ),
      ];
    }

    final disease = _mapOrEmpty(result['disease']);
    final suggestions = disease['suggestions'];
    if (suggestions is! List) {
      return const [_conditionUncertainHint];
    }

    final hints = <ExternalPlantConditionEventHint>[];
    for (final suggestion in suggestions) {
      if (suggestion is! Map) {
        continue;
      }

      final hint = _hintFromSuggestion(Map<String, dynamic>.from(suggestion));
      if (hint == null) {
        continue;
      }

      hints.add(hint);
      if (hints.length == 3) {
        break;
      }
    }

    return hints.isEmpty ? const [_conditionUncertainHint] : hints;
  }

  ExternalPlantConditionEventHint? _hintFromSuggestion(
    Map<String, dynamic> suggestion,
  ) {
    final eventType = _eventTypeFromEvidence(
      _evidenceFromSuggestion(suggestion),
    );
    if (eventType == null) {
      return null;
    }

    return ExternalPlantConditionEventHint(
      eventType: eventType,
      confidence: _normalizedConfidence(suggestion['probability']),
      note: _koreanNoteFromSuggestion(suggestion),
    );
  }

  List<String> _evidenceFromSuggestion(Map<String, dynamic> suggestion) {
    final details = _mapOrEmpty(suggestion['details']);
    return [
      ?_normalizedEvidence(suggestion['name']),
      ?_normalizedEvidence(details['local_name']),
      ..._normalizedEvidenceList(details['classification']),
      ..._normalizedEvidenceList(details['common_names']),
    ];
  }

  String? _eventTypeFromEvidence(List<String> evidence) {
    if (_matchesAny(evidence, const [
      'overwatering',
      'water excess',
      'excess water',
      'uneven watering',
      '과습',
      '물 과다',
      '불균형한 물주기',
    ])) {
      return PlantAnalysisEventTypes.overwaterSuspected;
    }

    if (_matchesAny(evidence, const [
      'underwatering',
      'water deficiency',
      'water shortage',
      'insufficient water',
      'drought stress',
      '수분 부족',
      '물 부족',
      '건조 스트레스',
    ])) {
      return PlantAnalysisEventTypes.waterNeeded;
    }

    if (_matchesAny(evidence, const [
      'sunburn',
      'excessive sunlight',
      'too much sun',
      'high light stress',
      '일소',
      '햇빛 과다',
      '강한 햇빛',
    ])) {
      return PlantAnalysisEventTypes.tooMuchSunSuspected;
    }

    if (_matchesAny(evidence, const [
      'insufficient light',
      'light deficiency',
      'low light',
      'etiolation',
      '빛 부족',
      '광량 부족',
    ])) {
      return PlantAnalysisEventTypes.lightNeeded;
    }

    if (_matchesAny(evidence, const [
      'animalia',
      'insecta',
      'pest',
      'pests',
      'insect',
      'insects',
      'mite',
      'mites',
      'aphid',
      'thrip',
      'scale insect',
      '해충',
      '벌레',
      '진드기',
      '응애',
      '진딧물',
      '총채벌레',
      '깍지벌레',
    ])) {
      return PlantAnalysisEventTypes.pestSuspected;
    }

    if (_matchesAny(evidence, const [
      'fungi',
      'fungus',
      'fungal',
      'bacterial',
      'bacteria',
      'viral',
      'virus',
      'mildew',
      'blight',
      'rust',
      'root rot',
      '곰팡이',
      '세균',
      '바이러스',
      '병해',
      '뿌리썩음',
    ])) {
      return PlantAnalysisEventTypes.diseaseSuspected;
    }

    if (_matchesAny(evidence, const [
      'root bound',
      'rootbound',
      'root crowding',
      'repotting',
      '분갈이',
      '뿌리 과밀',
    ])) {
      return PlantAnalysisEventTypes.repottingSuggested;
    }

    if (_matchesAny(evidence, const [
      'nutrient deficiency',
      'soil related issue',
      'soil issue',
      '영양 결핍',
      '토양 문제',
    ])) {
      return PlantAnalysisEventTypes.soilCheckNeeded;
    }

    if (_matchesAny(evidence, const [
      'frost',
      'cold stress',
      'heat stress',
      'temperature stress',
      '냉해',
      '동해',
      '고온 스트레스',
      '저온 스트레스',
      '온도 스트레스',
    ])) {
      return PlantAnalysisEventTypes.temperatureStressSuspected;
    }

    if (_matchesAny(evidence, const [
      'humidity issue',
      'humidity stress',
      'low humidity',
      'high humidity',
      '습도 문제',
      '습도 스트레스',
    ])) {
      return PlantAnalysisEventTypes.humidityIssueSuspected;
    }

    if (_matchesAny(evidence, const [
      'new leaf observed',
      'new leaves',
      '새 잎',
      '새잎',
      '새순',
    ])) {
      return PlantAnalysisEventTypes.newLeafObserved;
    }

    if (_matchesAny(evidence, const [
      'flowering observed',
      'currently blooming',
      'flower bloom',
      '개화 중',
      '꽃이 핌',
    ])) {
      return PlantAnalysisEventTypes.floweringObserved;
    }

    if (_matchesAny(evidence, const [
      'positive growth',
      'healthy new growth',
      '성장 양호',
      '새로운 성장',
    ])) {
      return PlantAnalysisEventTypes.growthPositive;
    }

    return null;
  }

  bool _matchesAny(List<String> evidence, List<String> patterns) {
    for (final value in evidence) {
      for (final pattern in patterns) {
        if (value == pattern || value.contains(pattern)) {
          return true;
        }
      }
    }

    return false;
  }

  String? _koreanNoteFromSuggestion(Map<String, dynamic> suggestion) {
    final details = _mapOrEmpty(suggestion['details']);
    final label = _firstKoreanLabel([
      details['local_name'],
      suggestion['name'],
      ..._objectList(details['common_names']),
    ]);

    return label == null ? null : '사진에서 $label 관련 신호가 있을 수 있어요.';
  }

  String? _firstKoreanLabel(List<Object?> values) {
    for (final value in values) {
      final label = _trimmedOrNull(value);
      if (label != null && _hasHangul(label)) {
        return label;
      }
    }

    return null;
  }

  bool _hasHangul(String value) {
    return RegExp(r'[\uac00-\ud7a3]').hasMatch(value);
  }

  DateTime? _createdAt(Object? value, DateTime? fallback) {
    final epochSeconds = value is num
        ? value.toDouble()
        : double.tryParse('${value ?? ''}');
    if (epochSeconds != null && epochSeconds.isFinite) {
      return DateTime.fromMillisecondsSinceEpoch(
        (epochSeconds * 1000).round(),
        isUtc: true,
      );
    }

    final text = _trimmedOrNull(value);
    if (text != null) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }

    return fallback;
  }

  double? _normalizedConfidence(Object? value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null || !parsed.isFinite) {
      return null;
    }

    if (parsed < 0) {
      return 0;
    }
    if (parsed > 1) {
      return 1;
    }

    return parsed;
  }

  List<String> _normalizedEvidenceList(Object? value) {
    return _objectList(
      value,
    ).map(_normalizedEvidence).whereType<String>().toList(growable: false);
  }

  String? _normalizedEvidence(Object? value) {
    final text = _trimmedOrNull(value);
    if (text == null) {
      return null;
    }

    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-/]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<Object?> _objectList(Object? value) {
    if (value is List) {
      return value;
    }

    return const [];
  }

  Map<String, dynamic> _mapOrEmpty(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  String? _trimmedOrNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

const _conditionUncertainHint = ExternalPlantConditionEventHint(
  eventType: PlantAnalysisEventTypes.conditionUncertain,
);
