import 'dart:convert';

import 'daily_keyword_candidate.dart';

final class DailyKeywordContextDocument {
  DailyKeywordContextDocument({
    required DateTime date,
    required String locale,
    required String regionCode,
    required DateTime generatedAt,
    required String sourceVersion,
    required Iterable<DailyKeywordCandidate> keywords,
    this.schemaVersion = currentSchemaVersion,
  }) : date = DateTime.utc(date.year, date.month, date.day),
       locale = locale.trim(),
       regionCode = regionCode.trim(),
       generatedAt = generatedAt.toUtc(),
       sourceVersion = sourceVersion.trim(),
       keywords = List.unmodifiable(keywords);

  factory DailyKeywordContextDocument.fromJson(Map<String, Object?> json) {
    final schemaVersion = _requiredString(json, 'schemaVersion');
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported schemaVersion: $schemaVersion. '
        'Expected $currentSchemaVersion.',
      );
    }

    final keywordValues = json['keywords'];
    if (keywordValues is! List<Object?>) {
      throw const FormatException('keywords must be a list.');
    }

    return DailyKeywordContextDocument(
      schemaVersion: schemaVersion,
      date: _parseDateOnly(_requiredString(json, 'date')),
      locale: _requiredString(json, 'locale'),
      regionCode: _requiredString(json, 'regionCode'),
      generatedAt: _parseDateTime(
        _requiredString(json, 'generatedAt'),
        'generatedAt',
      ),
      sourceVersion: _requiredString(json, 'sourceVersion'),
      keywords: keywordValues.map(
        (value) => DailyKeywordCandidate.fromJson(
          _stringKeyedMap(value, 'keywords item'),
        ),
      ),
    );
  }

  factory DailyKeywordContextDocument.decode(String source) {
    final decoded = jsonDecode(source);
    return DailyKeywordContextDocument.fromJson(
      _stringKeyedMap(decoded, 'document'),
    );
  }

  static const currentSchemaVersion = 'daily-keyword-context/v1';

  final String schemaVersion;
  final DateTime date;
  final String locale;
  final String regionCode;
  final DateTime generatedAt;
  final String sourceVersion;
  final List<DailyKeywordCandidate> keywords;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'date': _formatDateOnly(date),
      'locale': locale,
      'regionCode': regionCode,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'sourceVersion': sourceVersion,
      'keywords': keywords.map((keyword) => keyword.toJson()).toList(),
    };
  }

  String encode({bool pretty = false}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(toJson());
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key must be a string.');
    }
    return value;
  }

  static DateTime _parseDateOnly(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('date must use YYYY-MM-DD format.');
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw FormatException('date is not a valid calendar date: $value.');
    }
    return parsed;
  }

  static DateTime _parseDateTime(String value, String key) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$key must be an ISO-8601 date-time.');
    }
    return parsed.toUtc();
  }

  static String _formatDateOnly(DateTime value) {
    final utc = DateTime.utc(value.year, value.month, value.day);
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static Map<String, Object?> _stringKeyedMap(Object? value, String label) {
    if (value is! Map<Object?, Object?>) {
      throw FormatException('$label must be an object.');
    }

    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('$label must use string keys.');
      }
      result[key] = entry.value;
    }
    return result;
  }
}
