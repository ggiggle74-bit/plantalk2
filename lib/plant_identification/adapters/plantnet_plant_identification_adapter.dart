import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/plant_identification_candidate.dart';
import '../models/plant_identification_input.dart';
import '../models/plant_identification_result.dart';
import 'plant_identification_adapter.dart';

class PlantNetPlantIdentificationAdapter implements PlantIdentificationAdapter {
  const PlantNetPlantIdentificationAdapter({
    required this.apiKey,
    this.project = 'all',
    this.maxResults = 5,
    this.baseUrl = 'https://my-api.plantnet.org/v2',
  });

  final String apiKey;
  final String project;
  final int maxResults;
  final String baseUrl;

  @override
  String get providerKey => 'plantnet';

  @override
  Future<PlantIdentificationResult> identify(
    PlantIdentificationInput input,
  ) async {
    final normalizedApiKey = apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      throw StateError('Pl@ntNet API key is missing.');
    }

    final imageBytes = input.imageBytes;
    if (imageBytes == null || imageBytes.isEmpty) {
      throw StateError('Pl@ntNet identification requires image bytes.');
    }

    final mimeType =
        _supportedMimeType(input.mimeType) ??
        _supportedMimeType(_inferMimeType(input.fileName ?? input.imageUrl));
    if (mimeType == null) {
      throw UnsupportedError(
        'Pl@ntNet identification supports image/jpeg and image/png only.',
      );
    }

    final request = http.MultipartRequest('POST', _requestUri(input))
      ..headers['accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytes,
          filename: _fileNameFor(input, mimeType),
          contentType: MediaType.parse(mimeType),
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Pl@ntNet identification failed with HTTP ${response.statusCode}: ${_shortBody(body)}',
      );
    }

    return _resultFromJson(body, input);
  }

  String _shortBody(String body) {
    final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return '<empty body>';
    if (compact.length <= 300) return compact;
    return '${compact.substring(0, 300)}...';
  }

  Uri _requestUri(PlantIdentificationInput input) {
    final base = Uri.parse(baseUrl);
    final projectKey = project.trim().isEmpty ? 'all' : project.trim();
    final pathSegments = [
      ...base.pathSegments.where((segment) => segment.isNotEmpty),
      'identify',
      projectKey,
    ];

    return base.replace(
      pathSegments: pathSegments,
      queryParameters: {
        'api-key': apiKey.trim(),
        'lang': _plantNetLanguage(input.locale),
        'nb-results': maxResults.toString(),
      },
    );
  }

  PlantIdentificationResult _resultFromJson(
    String body,
    PlantIdentificationInput input,
  ) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected Pl@ntNet response shape.');
    }

    final rawResults = decoded['results'];
    if (rawResults is! List) {
      throw const FormatException('Missing Pl@ntNet results.');
    }

    final candidates = <PlantIdentificationCandidate>[];
    for (var index = 0; index < rawResults.length; index++) {
      final rawResult = rawResults[index];
      if (rawResult is Map<String, dynamic>) {
        candidates.add(_candidateFromResult(rawResult, index + 1));
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
    final version = _trimmedOrNull(decoded['version']);
    final predictedOrgans = _trimmedStringList(decoded['predictedOrgans']);

    return {
      'version': ?version,
      if (predictedOrgans.isNotEmpty) 'predictedOrgans': predictedOrgans,
    };
  }

  String _fileNameFor(PlantIdentificationInput input, String mimeType) {
    final fileName = _trimmedOrNull(input.fileName);
    if (fileName != null) {
      return fileName;
    }

    return mimeType == 'image/png' ? 'plant.png' : 'plant.jpg';
  }

  String? _supportedMimeType(String? mimeType) {
    final normalized = _trimmedOrNull(mimeType)?.toLowerCase();
    if (normalized == 'image/jpeg' || normalized == 'image/png') {
      return normalized;
    }

    return null;
  }

  String? _inferMimeType(String? fileNameOrPath) {
    final value = _trimmedOrNull(
      fileNameOrPath,
    )?.toLowerCase().split('?').first;
    if (value == null) return null;

    if (value.endsWith('.jpg') || value.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (value.endsWith('.png')) {
      return 'image/png';
    }

    return null;
  }

  String _plantNetLanguage(String locale) {
    final language = locale.toLowerCase().split(RegExp(r'[-_]')).first.trim();
    const supportedLanguages = {
      'ar',
      'cs',
      'de',
      'el',
      'en',
      'es',
      'fi',
      'fr',
      'he',
      'id',
      'it',
      'nl',
      'pl',
      'pt',
      'ru',
      'sk',
      'tr',
      'uk',
      'zh',
    };

    return supportedLanguages.contains(language) ? language : 'en';
  }

  Map<String, dynamic> _mapOrEmpty(Object? value) {
    return value is Map<String, dynamic> ? value : const <String, dynamic>{};
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
