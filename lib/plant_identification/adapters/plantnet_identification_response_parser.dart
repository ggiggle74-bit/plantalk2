import 'dart:convert';

import '../models/plant_identification_candidate.dart';
import '../models/plant_identification_input.dart';
import '../models/plant_identification_result.dart';

class PlantNetIdentificationResponseParser {
  const PlantNetIdentificationResponseParser();

  PlantIdentificationResult resultFromJson(
    String body,
    PlantIdentificationInput input, {
    required String providerKey,
  }) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected Pl@ntNet response shape.');
    }

    return resultFromMap(
      Map<String, dynamic>.from(decoded),
      input,
      providerKey: providerKey,
    );
  }

  PlantIdentificationResult resultFromMap(
    Map<String, dynamic> decoded,
    PlantIdentificationInput input, {
    required String providerKey,
  }) {
    final rawResults = decoded['results'];
    if (rawResults is! List) {
      throw const FormatException('Missing Pl@ntNet results.');
    }

    final candidates = <PlantIdentificationCandidate>[];
    for (var index = 0; index < rawResults.length; index++) {
      final rawResult = rawResults[index];
      if (rawResult is Map) {
        candidates.add(
          _candidateFromResult(
            Map<String, dynamic>.from(rawResult),
            index + 1,
            providerKey,
          ),
        );
      }
    }

    return PlantIdentificationResult(
      providerKey: providerKey,
      candidates: candidates,
      isMock: false,
      observedAt: input.requestedAt,
      metadata: _smallResultMetadata(decoded),
    );
  }

  PlantIdentificationCandidate _candidateFromResult(
    Map<String, dynamic> result,
    int rank,
    String providerKey,
  ) {
    final species = _mapOrEmpty(result['species']);
    final commonNames = _trimmedStringList(species['commonNames']);
    final bestMatch = _trimmedOrNull(result['bestMatch']);
    final scientificName = _firstNonEmpty([
      species['scientificName'],
      species['scientificNameWithoutAuthor'],
    ]);
    final gbifId = _nestedTrimmed(result, 'gbif', 'id');
    final powoId = _nestedTrimmed(result, 'powo', 'id');

    return PlantIdentificationCandidate(
      displayName:
          _firstNonEmpty([
            if (commonNames.isNotEmpty) commonNames.first,
            scientificName,
            bestMatch,
          ]) ??
          '\uc54c \uc218 \uc5c6\ub294 \uc2dd\ubb3c',
      scientificName: scientificName,
      commonNames: commonNames,
      confidence: _normalizedScore(result['score']),
      source: providerKey,
      candidateRank: rank,
      rawId: _firstNonEmpty([gbifId, powoId, scientificName]),
      metadata: {'bestMatch': ?bestMatch, 'gbifId': ?gbifId, 'powoId': ?powoId},
    );
  }

  Map<String, dynamic> _smallResultMetadata(Map<String, dynamic> decoded) {
    final bestMatch = _trimmedOrNull(decoded['bestMatch']);
    final remainingIdentificationRequests =
        decoded['remainingIdentificationRequests'];
    final version = _trimmedOrNull(decoded['version']);
    final predictedOrgans = _trimmedStringList(decoded['predictedOrgans']);

    return {
      'bestMatch': ?bestMatch,
      if (remainingIdentificationRequests is num)
        'remainingIdentificationRequests': remainingIdentificationRequests,
      'version': ?version,
      if (predictedOrgans.isNotEmpty) 'predictedOrgans': predictedOrgans,
    };
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

  List<String> _trimmedStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map(_trimmedOrNull)
        .whereType<String>()
        .toList(growable: false);
  }

  String? _nestedTrimmed(
    Map<String, dynamic> parent,
    String objectKey,
    String valueKey,
  ) {
    return _trimmedOrNull(_mapOrEmpty(parent[objectKey])[valueKey]);
  }

  String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _trimmedOrNull(value);
      if (text != null) {
        return text;
      }
    }

    return null;
  }

  String? _trimmedOrNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  double? _normalizedScore(Object? value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null) {
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
}
