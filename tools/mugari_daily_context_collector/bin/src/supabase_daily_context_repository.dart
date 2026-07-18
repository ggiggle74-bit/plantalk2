import 'dart:convert';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';

typedef DailyContextStorageTransport =
    Future<DailyContextStorageResponse> Function(
      DailyContextStorageRequest request,
    );

final class DailyContextStorageRequest {
  DailyContextStorageRequest({
    required this.uri,
    required Map<String, String> headers,
    required this.body,
  }) : headers = Map.unmodifiable(headers);

  final Uri uri;
  final Map<String, String> headers;
  final String body;
}

final class DailyContextStorageResponse {
  const DailyContextStorageResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

final class DailyContextStorageException implements Exception {
  const DailyContextStorageException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode;
    return code == null
        ? 'DailyContextStorageException: $message'
        : 'DailyContextStorageException($code): $message';
  }
}

final class SupabaseDailyContextRepository {
  SupabaseDailyContextRepository({
    required String supabaseUrl,
    required String serviceRoleKey,
    required DailyContextStorageTransport transport,
  }) : _baseUri = _validateBaseUri(supabaseUrl),
       _serviceRoleKey = _validateSecret(serviceRoleKey),
       _transport = transport;

  static const tableName = 'daily_keyword_contexts';

  final Uri _baseUri;
  final String _serviceRoleKey;
  final DailyContextStorageTransport _transport;

  Future<void> upsert(DailyKeywordContextDocument document) async {
    final validation = const DailyKeywordContractValidator().validate(document);
    if (!validation.isValid) {
      throw const DailyContextStorageException(
        'daily context document failed contract validation',
      );
    }

    final uri = _baseUri.replace(
      path: '/rest/v1/$tableName',
      queryParameters: {
        'on_conflict': 'context_date,locale,region_code',
      },
    );
    final response = await _transport(
      DailyContextStorageRequest(
        uri: uri,
        headers: {
          'apikey': _serviceRoleKey,
          'Authorization': 'Bearer $_serviceRoleKey',
          'Content-Type': 'application/json; charset=utf-8',
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: jsonEncode({
          'context_date': _date(document.date),
          'locale': document.locale,
          'region_code': document.regionCode,
          'schema_version': document.schemaVersion,
          'generated_at': document.generatedAt.toUtc().toIso8601String(),
          'source_version': document.sourceVersion,
          'keywords': document.keywords
              .map((keyword) => keyword.toJson())
              .toList(),
          'updated_at': document.generatedAt.toUtc().toIso8601String(),
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DailyContextStorageException(
        'storage provider returned a non-success response',
        statusCode: response.statusCode,
      );
    }
  }

  static Uri _validateBaseUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError.value(
        '[redacted]',
        'supabaseUrl',
        'must be an HTTPS origin without path, query, or fragment',
      );
    }
    return uri.replace(path: '', query: null, fragment: null);
  }

  static String _validateSecret(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.contains(RegExp(r'\s')) ||
        normalized.length > 4096) {
      throw ArgumentError.value(
        '[redacted]',
        'serviceRoleKey',
        'must be a non-empty token without whitespace',
      );
    }
    return normalized;
  }

  static String _date(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
