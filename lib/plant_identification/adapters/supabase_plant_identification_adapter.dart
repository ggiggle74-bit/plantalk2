import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plant_identification_input.dart';
import '../models/plant_identification_result.dart';
import 'plant_identification_adapter.dart';
import 'plantnet_identification_response_parser.dart';

class SupabasePlantIdentificationAdapter implements PlantIdentificationAdapter {
  const SupabasePlantIdentificationAdapter({
    this.project = 'all',
    this.maxResults = 5,
    this.parser = const PlantNetIdentificationResponseParser(),
  });

  final String project;
  final int maxResults;
  final PlantNetIdentificationResponseParser parser;

  @override
  String get providerKey => 'plantnet';

  @override
  Future<PlantIdentificationResult> identify(
    PlantIdentificationInput input,
  ) async {
    final imageBytes = input.imageBytes;
    if (imageBytes == null || imageBytes.isEmpty) {
      throw StateError('Plant identification proxy requires image bytes.');
    }

    final mimeType =
        _supportedMimeType(input.mimeType) ??
        _supportedMimeType(_inferMimeType(input.fileName ?? input.imageUrl));
    if (mimeType == null) {
      throw UnsupportedError(
        'Plant identification proxy supports image/jpeg and image/png only.',
      );
    }

    final response = await Supabase.instance.client.functions.invoke(
      'plantnet-identify',
      body: {
        'imageBase64': base64Encode(imageBytes),
        'filename': _fileNameFor(input, mimeType),
        'contentType': mimeType,
        'project': project,
        'lang': _plantNetLanguage(input.locale),
        'nbResults': maxResults,
      },
    );

    final responseData = response.data;
    final decoded = _responseMap(responseData);
    return parser.resultFromMap(decoded, input, providerKey: providerKey);
  }

  Map<String, dynamic> _responseMap(Object? responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    if (responseData is Map) {
      return Map<String, dynamic>.from(responseData);
    }
    if (responseData is String) {
      final decoded = jsonDecode(responseData);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw const FormatException('Unexpected plant identification proxy shape.');
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

  String? _trimmedOrNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
