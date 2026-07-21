import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dialogue/daily_keywords/catalogs/blocked_keyword_catalog.dart';
import '../../dialogue/daily_keywords/daily_keyword_source.dart';
import '../../dialogue/daily_keywords/models/daily_keyword_candidate.dart';
import '../../dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import '../../dialogue/models/daily_keyword_context.dart';

typedef DailyKeywordContextRowFetcher =
    Future<Map<String, dynamic>?> Function({
      required String contextDate,
      required String locale,
      required String regionCode,
    });

class SupabaseDailyKeywordSource implements DailyKeywordSource {
  SupabaseDailyKeywordSource({
    required this.fetchRow,
    Duration timeout = const Duration(seconds: 2),
  }) : timeout = _validatedTimeout(timeout);

  factory SupabaseDailyKeywordSource.fromClient(
    SupabaseClient client, {
    Duration timeout = const Duration(seconds: 2),
  }) {
    return SupabaseDailyKeywordSource(
      timeout: timeout,
      fetchRow:
          ({
            required contextDate,
            required locale,
            required regionCode,
          }) async {
            final row = await client
                .from(tableName)
                .select(
                  'context_date, locale, region_code, schema_version, '
                  'generated_at, source_version, keywords',
                )
                .eq('context_date', contextDate)
                .eq('locale', locale)
                .eq('region_code', regionCode)
                .maybeSingle();

            return row == null ? null : Map<String, dynamic>.from(row);
          },
    );
  }

  static const tableName = 'daily_keyword_contexts';
  static const schemaVersion = 'daily-keyword-context/v1';
  static const maximumKeywordCount = 8;

  final DailyKeywordContextRowFetcher fetchRow;
  final Duration timeout;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) async {
    final locale = request.locale.trim();
    final regionCode = request.regionCode.trim();
    if (locale.isEmpty || regionCode.isEmpty) {
      throw const FormatException(
        'Daily keyword locale and region code are required.',
      );
    }

    final contextDate = _formatDate(request.date);
    final row = await fetchRow(
      contextDate: contextDate,
      locale: locale,
      regionCode: regionCode,
    ).timeout(timeout);

    if (row == null) {
      return _emptyContext(request);
    }

    return _parseRow(
      row,
      request: request,
      expectedDate: contextDate,
      expectedLocale: locale,
      expectedRegionCode: regionCode,
    );
  }

  DailyKeywordContext _parseRow(
    Map<String, dynamic> row, {
    required DailyKeywordSourceRequest request,
    required String expectedDate,
    required String expectedLocale,
    required String expectedRegionCode,
  }) {
    final contextDate = _requiredString(row, 'context_date');
    final locale = _requiredString(row, 'locale');
    final regionCode = _requiredString(row, 'region_code');
    final rowSchemaVersion = _requiredString(row, 'schema_version');
    final generatedAtText = _requiredString(row, 'generated_at');
    final sourceVersion = _requiredString(row, 'source_version');

    if (contextDate != expectedDate ||
        locale != expectedLocale ||
        regionCode != expectedRegionCode ||
        rowSchemaVersion != schemaVersion) {
      throw const FormatException(
        'Daily keyword row did not match the requested context.',
      );
    }

    final parsedDate = DateTime.tryParse(contextDate);
    final generatedAt = DateTime.tryParse(generatedAtText);
    if (parsedDate == null || generatedAt == null) {
      throw const FormatException(
        'Daily keyword row contained an invalid timestamp.',
      );
    }

    final rawKeywords = row['keywords'];
    if (rawKeywords is! List ||
        rawKeywords.length > maximumKeywordCount) {
      throw const FormatException(
        'Daily keyword row contained an invalid keyword collection.',
      );
    }

    final keywords = <DailyKeywordEntry>[];
    for (final rawKeyword in rawKeywords) {
      if (rawKeyword is! Map) {
        continue;
      }

      final normalized = rawKeyword.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final entry = _parseEntry(normalized);
      if (entry != null) {
        keywords.add(entry);
      }
    }

    return DailyKeywordContext(
      date: parsedDate,
      locale: locale,
      generatedAt: generatedAt.toUtc(),
      sourceVersion: sourceVersion,
      keywords: keywords,
    );
  }

  DailyKeywordEntry? _parseEntry(Map<String, dynamic> row) {
    try {
      final type = _requiredString(row, 'type').toLowerCase();
      final keyword = _requiredString(row, 'keyword');
      final hint = _requiredString(row, 'hint');
      final category = _optionalString(row, 'category');
      final plantHint = _requiredString(row, 'plantHint');
      final tone = _requiredString(row, 'tone').toLowerCase();
      final relevanceScore = _optionalScore(row, 'relevanceScore');
      final fitScore = _requiredScore(row, 'fitScore');
      final targetAgeBands = _ageBands(row['targetAgeBands']);
      _validateConversationAngles(row['conversationAngles']);

      if (!DailyKeywordTypes.allowed.contains(type) ||
          !DailyKeywordTones.allowed.contains(tone) ||
          fitScore < 0.60 ||
          [
            keyword,
            hint,
            category ?? '',
            plantHint,
          ].any(BlockedKeywordCatalog.containsBlockedTerm)) {
        return null;
      }

      return DailyKeywordEntry(
        type: type,
        keyword: keyword,
        hint: hint,
        category: category,
        relevanceScore: relevanceScore,
        plantHint: plantHint,
        tone: tone,
        fitScore: fitScore,
        targetAgeBands: targetAgeBands,
      );
    } on FormatException {
      return null;
    }
  }

  static DailyKeywordContext _emptyContext(
    DailyKeywordSourceRequest request,
  ) {
    return DailyKeywordContext(
      date: request.date,
      locale: request.locale,
      keywords: const [],
    );
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Daily keyword row requires $key.');
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Daily keyword row has invalid $key.');
    }
    return value.trim();
  }

  static double _requiredScore(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! num) {
      throw FormatException('Daily keyword row requires numeric $key.');
    }
    final score = value.toDouble();
    if (!score.isFinite || score < 0 || score > 1) {
      throw FormatException('Daily keyword row has invalid $key.');
    }
    return score;
  }

  static double? _optionalScore(Map<String, dynamic> row, String key) {
    if (row[key] == null) {
      return null;
    }
    return _requiredScore(row, key);
  }

  static List<String> _ageBands(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw const FormatException(
        'Daily keyword target age bands must be a list.',
      );
    }

    final result = <String>[];
    for (final ageBand in value) {
      if (ageBand is! String ||
          !DailyKeywordAgeBands.allowed.contains(ageBand.trim()) ||
          result.contains(ageBand.trim())) {
        throw const FormatException(
          'Daily keyword target age bands were invalid.',
        );
      }
      result.add(ageBand.trim());
    }
    return List.unmodifiable(result);
  }

  static void _validateConversationAngles(Object? value) {
    if (value is! List || value.isEmpty || value.length > 4) {
      throw const FormatException(
        'Daily keyword conversation angles were invalid.',
      );
    }
    if (value.any(
      (angle) => angle is! String || angle.trim().isEmpty,
    )) {
      throw const FormatException(
        'Daily keyword conversation angles were invalid.',
      );
    }
  }

  static String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  }

  static Duration _validatedTimeout(Duration value) {
    if (value <= Duration.zero) {
      throw ArgumentError.value(value, 'timeout', 'must be positive');
    }
    return value;
  }
}
