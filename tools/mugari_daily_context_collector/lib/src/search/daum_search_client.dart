import 'dart:convert';

import '../models/search_document.dart';
import '../planning/daily_search_query.dart';

typedef SearchHttpTransport =
    Future<SearchHttpResponse> Function(SearchHttpRequest request);

final class SearchHttpRequest {
  SearchHttpRequest({
    required this.uri,
    required Map<String, String> headers,
  }) : headers = Map.unmodifiable(headers);

  final Uri uri;
  final Map<String, String> headers;
}

final class SearchHttpResponse {
  const SearchHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

final class DaumSearchResult {
  DaumSearchResult({
    required this.pageableCount,
    required this.totalCount,
    required this.isEnd,
    required Iterable<SearchDocument> documents,
  }) : documents = List.unmodifiable(documents);

  final int pageableCount;
  final int totalCount;
  final bool isEnd;
  final List<SearchDocument> documents;
}

final class DaumSearchException implements Exception {
  const DaumSearchException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode;
    return code == null
        ? 'DaumSearchException: $message'
        : 'DaumSearchException($code): $message';
  }
}

final class DaumSearchClient {
  DaumSearchClient({
    required String restApiKey,
    required SearchHttpTransport transport,
    Uri? baseUri,
  }) : _restApiKey = _validateApiKey(restApiKey),
       _transport = transport,
       _baseUri = baseUri ?? Uri.https('dapi.kakao.com');

  final String _restApiKey;
  final SearchHttpTransport _transport;
  final Uri _baseUri;

  Future<DaumSearchResult> searchWeb(
    DailySearchQuery query, {
    int page = 1,
    int size = 10,
    String sort = 'accuracy',
  }) {
    return _search(
      query,
      source: SearchDocumentSources.web,
      path: '/v2/search/web',
      page: page,
      size: size,
      sort: sort,
    );
  }

  Future<DaumSearchResult> searchBlog(
    DailySearchQuery query, {
    int page = 1,
    int size = 10,
    String sort = 'accuracy',
  }) {
    return _search(
      query,
      source: SearchDocumentSources.blog,
      path: '/v2/search/blog',
      page: page,
      size: size,
      sort: sort,
    );
  }

  Future<DaumSearchResult> _search(
    DailySearchQuery query, {
    required String source,
    required String path,
    required int page,
    required int size,
    required String sort,
  }) async {
    if (page < 1 || page > 50) {
      throw ArgumentError.value(page, 'page', 'must be between 1 and 50');
    }
    if (size < 1 || size > 50) {
      throw ArgumentError.value(size, 'size', 'must be between 1 and 50');
    }
    if (sort != 'accuracy' && sort != 'recency') {
      throw ArgumentError.value(
        sort,
        'sort',
        'must be accuracy or recency',
      );
    }

    final uri = _baseUri.replace(
      path: path,
      queryParameters: {
        'query': query.text,
        'sort': sort,
        'page': '$page',
        'size': '$size',
      },
    );
    final response = await _transport(
      SearchHttpRequest(
        uri: uri,
        headers: {'Authorization': 'KakaoAK $_restApiKey'},
      ),
    );

    if (response.statusCode != 200) {
      throw DaumSearchException(
        'search provider returned a non-success response',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const DaumSearchException('search provider returned invalid JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const DaumSearchException(
        'search provider response must be a JSON object',
      );
    }

    final meta = _requiredMap(decoded, 'meta');
    final rawDocuments = decoded['documents'];
    if (rawDocuments is! List<Object?>) {
      throw const DaumSearchException(
        'search provider documents must be a list',
      );
    }

    final documents = <SearchDocument>[];
    final seenUrls = <String>{};
    for (final rawDocument in rawDocuments) {
      if (rawDocument is! Map<String, Object?>) {
        throw const DaumSearchException(
          'search provider document must be an object',
        );
      }
      final url = Uri.tryParse(_requiredString(rawDocument, 'url'));
      if (url == null) {
        throw const DaumSearchException(
          'search provider document URL is invalid',
        );
      }
      if (!seenUrls.add(url.toString())) {
        continue;
      }

      final datetime = _optionalDateTime(rawDocument, 'datetime');
      documents.add(
        SearchDocument.fromQuery(
          source: source,
          query: query,
          title: _requiredString(rawDocument, 'title'),
          snippet: _requiredString(rawDocument, 'contents'),
          url: url,
          publishedAt: datetime,
        ),
      );
    }

    return DaumSearchResult(
      pageableCount: _requiredInt(meta, 'pageable_count'),
      totalCount: _requiredInt(meta, 'total_count'),
      isEnd: _requiredBool(meta, 'is_end'),
      documents: documents,
    );
  }

  static String _validateApiKey(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.contains(RegExp(r'\s')) ||
        normalized.length > 256) {
      throw ArgumentError.value(
        '[redacted]',
        'restApiKey',
        'must be a non-empty token without whitespace',
      );
    }
    return normalized;
  }

  static Map<String, Object?> _requiredMap(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is! Map<String, Object?>) {
      throw DaumSearchException('$key must be an object');
    }
    return value;
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw DaumSearchException('$key must be a string');
    }
    return value;
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw DaumSearchException('$key must be an integer');
    }
    return value;
  }

  static bool _requiredBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw DaumSearchException('$key must be a boolean');
    }
    return value;
  }

  static DateTime? _optionalDateTime(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value == null || value == '') {
      return null;
    }
    if (value is! String) {
      throw DaumSearchException('$key must be a string when present');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw DaumSearchException('$key must be an ISO-8601 date-time');
    }
    return parsed.toUtc();
  }
}
