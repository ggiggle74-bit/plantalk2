import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'daum_search_client.dart';

final class SearchTransportException implements Exception {
  const SearchTransportException(this.message);

  final String message;

  @override
  String toString() => 'SearchTransportException: $message';
}

final class DartIoSearchHttpTransport {
  DartIoSearchHttpTransport({
    this.timeout = const Duration(seconds: 10),
    this.maximumResponseBytes = 1024 * 1024,
    Set<String> allowedHosts = const {'dapi.kakao.com'},
  }) : allowedHosts = Set.unmodifiable(
         allowedHosts.map((host) => host.trim().toLowerCase()),
       ) {
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
    if (this.allowedHosts.isEmpty ||
        this.allowedHosts.any((host) => host.isEmpty)) {
      throw ArgumentError.value(
        allowedHosts,
        'allowedHosts',
        'must contain non-empty hosts',
      );
    }
  }

  final Duration timeout;
  final int maximumResponseBytes;
  final Set<String> allowedHosts;

  Future<SearchHttpResponse> call(SearchHttpRequest input) async {
    final uri = input.uri;
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !allowedHosts.contains(uri.host.toLowerCase())) {
      throw const SearchTransportException(
        'search request target is not allowed',
      );
    }

    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      input.headers.forEach(request.headers.set);
      final response = await request.close().timeout(timeout);
      final bytes = await _readBounded(response).timeout(timeout);
      return SearchHttpResponse(
        statusCode: response.statusCode,
        body: utf8.decode(bytes),
      );
    } on SearchTransportException {
      rethrow;
    } on TimeoutException {
      throw const SearchTransportException('search request timed out');
    } on FormatException {
      throw const SearchTransportException(
        'search response was not valid UTF-8',
      );
    } on SocketException {
      throw const SearchTransportException('search provider was unavailable');
    } on HttpException {
      throw const SearchTransportException('search request failed');
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List> _readBounded(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (builder.length + chunk.length > maximumResponseBytes) {
        throw const SearchTransportException(
          'search response exceeded the size limit',
        );
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
