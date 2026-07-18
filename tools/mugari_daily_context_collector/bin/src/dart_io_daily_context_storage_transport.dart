import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'supabase_daily_context_repository.dart';

final class DartIoDailyContextStorageTransport {
  DartIoDailyContextStorageTransport({
    required String supabaseUrl,
    this.timeout = const Duration(seconds: 10),
    this.maximumResponseBytes = 1024 * 1024,
  }) : _allowedOrigin = _origin(supabaseUrl) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    if (maximumResponseBytes < 1) {
      throw ArgumentError.value(
        maximumResponseBytes,
        'maximumResponseBytes',
        'must be positive',
      );
    }
  }

  final Uri _allowedOrigin;
  final Duration timeout;
  final int maximumResponseBytes;

  Future<DailyContextStorageResponse> call(
    DailyContextStorageRequest input,
  ) async {
    final expectedPath =
        '/rest/v1/${SupabaseDailyContextRepository.tableName}';
    if (input.uri.scheme != _allowedOrigin.scheme ||
        input.uri.host.toLowerCase() != _allowedOrigin.host.toLowerCase() ||
        input.uri.port != _allowedOrigin.port ||
        input.uri.userInfo.isNotEmpty ||
        input.uri.hasFragment ||
        input.uri.path != expectedPath) {
      throw const DailyContextStorageException(
        'storage request target is not allowed',
      );
    }

    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final request = await client.postUrl(input.uri).timeout(timeout);
      request.followRedirects = false;
      input.headers.forEach(request.headers.set);
      final bodyBytes = utf8.encode(input.body);
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);
      final response = await request.close().timeout(timeout);
      final responseBytes = await _readBounded(response).timeout(timeout);
      return DailyContextStorageResponse(
        statusCode: response.statusCode,
        body: utf8.decode(responseBytes),
      );
    } on DailyContextStorageException {
      rethrow;
    } on TimeoutException {
      throw const DailyContextStorageException('storage request timed out');
    } on FormatException {
      throw const DailyContextStorageException(
        'storage response was not valid UTF-8',
      );
    } on SocketException {
      throw const DailyContextStorageException(
        'storage provider was unavailable',
      );
    } on HttpException {
      throw const DailyContextStorageException('storage request failed');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<int>> _readBounded(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maximumResponseBytes) {
        throw const DailyContextStorageException(
          'storage response exceeded the size limit',
        );
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  static Uri _origin(String value) {
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
}
