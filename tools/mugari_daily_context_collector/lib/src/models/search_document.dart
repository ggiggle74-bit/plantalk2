import '../planning/daily_search_query.dart';
import 'daily_keyword_candidate.dart';

final class SearchDocumentSources {
  SearchDocumentSources._();

  static const web = 'web';
  static const blog = 'blog';

  static const allowed = {web, blog};
}

final class SearchDocument {
  SearchDocument({
    required String source,
    required String queryId,
    required String queryIntent,
    required String queryText,
    required this.queryPriority,
    required this.freshnessWindowDays,
    required String title,
    required String snippet,
    required Uri url,
    DateTime? publishedAt,
    Iterable<String> targetAgeBands = const [],
    this.regionScoped = false,
  }) : source = _validatedSource(source),
       queryId = _validatedQueryId(queryId),
       queryIntent = _validatedQueryIntent(queryIntent),
       queryText = _normalizedText(queryText),
       title = _normalizedText(title, allowEmpty: true),
       snippet = _normalizedText(snippet, allowEmpty: true),
       url = _validatedUrl(url),
       publishedAt = publishedAt?.toUtc(),
       targetAgeBands = _normalizedAgeBands(targetAgeBands) {
    if (queryPriority < 0 || queryPriority > 100) {
      throw ArgumentError.value(
        queryPriority,
        'queryPriority',
        'must be between 0 and 100',
      );
    }
    if (freshnessWindowDays < 1 || freshnessWindowDays > 90) {
      throw ArgumentError.value(
        freshnessWindowDays,
        'freshnessWindowDays',
        'must be between 1 and 90',
      );
    }
    if (this.title.isEmpty && this.snippet.isEmpty) {
      throw ArgumentError('title and snippet must not both be empty');
    }
  }

  factory SearchDocument.fromQuery({
    required String source,
    required DailySearchQuery query,
    required String title,
    required String snippet,
    required Uri url,
    DateTime? publishedAt,
  }) {
    return SearchDocument(
      source: source,
      queryId: query.id,
      queryIntent: query.intent,
      queryText: query.text,
      queryPriority: query.priority,
      freshnessWindowDays: query.freshnessWindowDays,
      title: title,
      snippet: snippet,
      url: url,
      publishedAt: publishedAt,
      targetAgeBands: query.targetAgeBands,
      regionScoped: query.regionScoped,
    );
  }

  factory SearchDocument.fromJson(Map<String, Object?> json) {
    return SearchDocument(
      source: _requiredString(json, 'source'),
      queryId: _requiredString(json, 'queryId'),
      queryIntent: _requiredString(json, 'queryIntent'),
      queryText: _requiredString(json, 'queryText'),
      queryPriority: _requiredInt(json, 'queryPriority'),
      freshnessWindowDays: _requiredInt(json, 'freshnessWindowDays'),
      title: _requiredString(json, 'title'),
      snippet: _requiredString(json, 'snippet'),
      url: Uri.parse(_requiredString(json, 'url')),
      publishedAt: _optionalDateTime(json, 'publishedAt'),
      targetAgeBands: _optionalStringList(json, 'targetAgeBands'),
      regionScoped: _optionalBool(json, 'regionScoped'),
    );
  }

  final String source;
  final String queryId;
  final String queryIntent;
  final String queryText;
  final int queryPriority;
  final int freshnessWindowDays;
  final String title;
  final String snippet;
  final Uri url;
  final DateTime? publishedAt;
  final List<String> targetAgeBands;
  final bool regionScoped;

  Map<String, Object?> toJson() {
    final timestamp = publishedAt;
    return {
      'source': source,
      'queryId': queryId,
      'queryIntent': queryIntent,
      'queryText': queryText,
      'queryPriority': queryPriority,
      'freshnessWindowDays': freshnessWindowDays,
      'title': title,
      'snippet': snippet,
      'url': url.toString(),
      if (timestamp != null)
        'publishedAt': timestamp.toUtc().toIso8601String(),
      if (targetAgeBands.isNotEmpty) 'targetAgeBands': targetAgeBands,
      'regionScoped': regionScoped,
    };
  }

  static String _validatedSource(String value) {
    final normalized = value.trim().toLowerCase();
    if (!SearchDocumentSources.allowed.contains(normalized)) {
      throw ArgumentError.value(value, 'source', 'is not supported');
    }
    return normalized;
  }

  static String _validatedQueryId(String value) {
    final normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{2,63}$').hasMatch(normalized)) {
      throw ArgumentError.value(value, 'queryId', 'must be a stable identifier');
    }
    return normalized;
  }

  static String _validatedQueryIntent(String value) {
    final normalized = value.trim().toLowerCase();
    if (!DailyQueryIntents.allowed.contains(normalized)) {
      throw ArgumentError.value(value, 'queryIntent', 'is not supported');
    }
    return normalized;
  }

  static String _normalizedText(String value, {bool allowEmpty = false}) {
    final normalized = value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (!allowEmpty && normalized.isEmpty) {
      throw ArgumentError.value(value, 'text', 'must not be empty');
    }
    return normalized;
  }

  static Uri _validatedUrl(Uri value) {
    final scheme = value.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || value.host.isEmpty) {
      throw ArgumentError.value(value, 'url', 'must be an absolute HTTP(S) URL');
    }
    return value;
  }

  static List<String> _normalizedAgeBands(Iterable<String> values) {
    final requested = <String>{};
    for (final value in values) {
      final normalized = value.trim().toLowerCase();
      if (!DailyKeywordAgeBands.allowed.contains(normalized)) {
        throw ArgumentError.value(value, 'targetAgeBands', 'is not supported');
      }
      requested.add(normalized);
    }

    return List.unmodifiable([
      for (final ageBand in DailyKeywordAgeBands.allowed)
        if (requested.contains(ageBand)) ageBand,
    ]);
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key must be a string.');
    }
    return value;
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('$key must be an integer.');
    }
    return value;
  }

  static bool _optionalBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return false;
    }
    if (value is! bool) {
      throw FormatException('$key must be a boolean when present.');
    }
    return value;
  }

  static DateTime? _optionalDateTime(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('$key must be a string when present.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$key must be an ISO-8601 date-time.');
    }
    return parsed.toUtc();
  }

  static List<String> _optionalStringList(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?>) {
      throw FormatException('$key must be a list when present.');
    }

    final result = <String>[];
    for (final item in value) {
      if (item is! String) {
        throw FormatException('$key must contain only strings.');
      }
      result.add(item);
    }
    return result;
  }
}
