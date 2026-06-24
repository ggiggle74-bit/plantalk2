import 'dart:convert';

import '../models/external_plant_analysis_result.dart';
import '../models/normalized_plant_event.dart';
import '../models/plant_analysis_input.dart';

class GeminiDefaultObservationImageQualities {
  const GeminiDefaultObservationImageQualities._();

  static const usable = 'usable';
  static const limited = 'limited';
  static const unusable = 'unusable';
}

class GeminiDefaultObservationStates {
  const GeminiDefaultObservationStates._();

  static const stableAppearance = 'stable_appearance';
  static const growthPositive = 'growth_positive';
  static const newLeafObserved = 'new_leaf_observed';
  static const floweringObserved = 'flowering_observed';
  static const visibleConcern = 'visible_concern';
  static const uncertain = 'uncertain';
}

class GeminiDefaultObservationEvidenceTags {
  const GeminiDefaultObservationEvidenceTags._();

  static const stableFoliage = 'stable_foliage';
  static const newGrowth = 'new_growth';
  static const newLeaf = 'new_leaf';
  static const flowering = 'flowering';
  static const visibleDiscoloration = 'visible_discoloration';
  static const visibleWilting = 'visible_wilting';
  static const visibleDamage = 'visible_damage';
  static const leafDrop = 'leaf_drop';
  static const imageUnclear = 'image_unclear';
}

class GeminiDefaultStateObservationParser {
  const GeminiDefaultStateObservationParser();

  static const providerKey = 'gemini_default_state_observation';

  ExternalPlantAnalysisResult resultFromJson(
    String body,
    PlantAnalysisInput input,
  ) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException(
        'Unexpected Gemini default-state observation response shape.',
      );
    }

    return resultFromMap(Map<String, dynamic>.from(decoded), input);
  }

  ExternalPlantAnalysisResult resultFromMap(
    Map<String, dynamic> decoded,
    PlantAnalysisInput input,
  ) {
    _validateAnalysisType(input.analysisType);
    final hint = _conditionEventHint(decoded);

    return ExternalPlantAnalysisResult(
      providerKey: providerKey,
      analysisType: PlantAnalysisTypes.defaultObservation,
      providerResultId: _trimmedOrNull(decoded['observation_id']),
      conditionEventHints: [hint],
      summary: hint.note,
      rawPayload: const <String, Object?>{},
      isMock: false,
      createdAt: _createdAt(decoded['observed_at'], input.requestedAt),
    );
  }

  void _validateAnalysisType(String analysisType) {
    if (analysisType == PlantAnalysisTypes.defaultObservation) {
      return;
    }

    throw UnsupportedError(
      'Gemini default-state observation supports default_observation only.',
    );
  }

  ExternalPlantConditionEventHint _conditionEventHint(
    Map<String, dynamic> decoded,
  ) {
    final imageQuality = _normalizedToken(decoded['image_quality']);
    final observationState = _normalizedToken(decoded['observation_state']);
    final evidenceTags = _normalizedEvidenceTags(decoded['evidence_tags']);

    if (imageQuality != GeminiDefaultObservationImageQualities.usable) {
      return _uncertainHint;
    }
    if (evidenceTags == null) {
      return _uncertainHint;
    }

    if (observationState == GeminiDefaultObservationStates.visibleConcern ||
        evidenceTags.any(_concernEvidenceTags.contains)) {
      return _visibleConcernHint;
    }

    switch (observationState) {
      case GeminiDefaultObservationStates.stableAppearance:
        return evidenceTags.contains(
              GeminiDefaultObservationEvidenceTags.stableFoliage,
            )
            ? _appearanceStableHint
            : _uncertainHint;
      case GeminiDefaultObservationStates.growthPositive:
        return evidenceTags.contains(
              GeminiDefaultObservationEvidenceTags.newGrowth,
            )
            ? _growthPositiveHint
            : _uncertainHint;
      case GeminiDefaultObservationStates.newLeafObserved:
        return evidenceTags.contains(
              GeminiDefaultObservationEvidenceTags.newLeaf,
            )
            ? _newLeafObservedHint
            : _uncertainHint;
      case GeminiDefaultObservationStates.floweringObserved:
        return evidenceTags.contains(
              GeminiDefaultObservationEvidenceTags.flowering,
            )
            ? _floweringObservedHint
            : _uncertainHint;
      case GeminiDefaultObservationStates.uncertain:
      default:
        return _uncertainHint;
    }
  }

  Set<String>? _normalizedEvidenceTags(Object? value) {
    if (value is! List) {
      return null;
    }

    final tags = <String>{};
    for (final item in value) {
      if (item is! String) {
        return null;
      }

      final tag = _normalizedToken(item);
      if (tag == null || !_allowedEvidenceTags.contains(tag)) {
        return null;
      }
      tags.add(tag);
    }

    return tags;
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

  String? _normalizedToken(Object? value) {
    final text = _trimmedOrNull(value);
    if (text == null) {
      return null;
    }

    return text.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_').trim();
  }

  String? _trimmedOrNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

const _allowedEvidenceTags = <String>{
  GeminiDefaultObservationEvidenceTags.stableFoliage,
  GeminiDefaultObservationEvidenceTags.newGrowth,
  GeminiDefaultObservationEvidenceTags.newLeaf,
  GeminiDefaultObservationEvidenceTags.flowering,
  GeminiDefaultObservationEvidenceTags.visibleDiscoloration,
  GeminiDefaultObservationEvidenceTags.visibleWilting,
  GeminiDefaultObservationEvidenceTags.visibleDamage,
  GeminiDefaultObservationEvidenceTags.leafDrop,
  GeminiDefaultObservationEvidenceTags.imageUnclear,
};

const _concernEvidenceTags = <String>{
  GeminiDefaultObservationEvidenceTags.visibleDiscoloration,
  GeminiDefaultObservationEvidenceTags.visibleWilting,
  GeminiDefaultObservationEvidenceTags.visibleDamage,
  GeminiDefaultObservationEvidenceTags.leafDrop,
  GeminiDefaultObservationEvidenceTags.imageUnclear,
};

const _appearanceStableHint = ExternalPlantConditionEventHint(
  eventType: PlantAnalysisEventTypes.appearanceStable,
  note: '사진에서 겉으로 보이는 상태가 비교적 안정적으로 보여요. 건강 진단 결과는 아니에요.',
);

const _growthPositiveHint = ExternalPlantConditionEventHint(
  eventType: PlantAnalysisEventTypes.growthPositive,
  note: '사진에서 새 성장 신호가 보여요. 기본 상태 관찰 결과예요.',
);

const _newLeafObservedHint = ExternalPlantConditionEventHint(
  eventType: PlantAnalysisEventTypes.newLeafObserved,
  note: '사진에서 새 잎이 보이는 것 같아요. 기본 상태 관찰 결과예요.',
);

const _floweringObservedHint = ExternalPlantConditionEventHint(
  eventType: PlantAnalysisEventTypes.floweringObserved,
  note: '사진에서 꽃이 피는 모습이 보여요. 기본 상태 관찰 결과예요.',
);

const _visibleConcernHint = ExternalPlantConditionEventHint(
  eventType: PlantAnalysisEventTypes.conditionUncertain,
  note: '사진에서 확인이 필요한 변화가 보일 수 있어요. 정확한 판단은 별도 건강 확인이 필요해요.',
);

const _uncertainHint = ExternalPlantConditionEventHint(
  eventType: PlantAnalysisEventTypes.conditionUncertain,
  note: '사진만으로는 기본 상태를 안정적으로 관찰하기 어려워요.',
);
