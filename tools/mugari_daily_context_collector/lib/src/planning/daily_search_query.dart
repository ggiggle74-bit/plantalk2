import '../models/daily_keyword_candidate.dart';

final class DailyQueryIntents {
  DailyQueryIntents._();

  static const weather = 'weather';
  static const nature = 'nature';
  static const seasonal = 'seasonal';
  static const park = 'park';
  static const environment = 'environment';
  static const culture = 'culture';
  static const region = 'region';
  static const audience = 'audience';

  static const allowed = {
    weather,
    nature,
    seasonal,
    park,
    environment,
    culture,
    region,
    audience,
  };
}

final class DailySearchQuery {
  DailySearchQuery({
    required String id,
    required String text,
    required String intent,
    required this.priority,
    required this.freshnessWindowDays,
    Iterable<String> targetAgeBands = const [],
    this.regionScoped = false,
  }) : id = _validatedId(id),
       text = _validatedText(text),
       intent = _validatedIntent(intent),
       targetAgeBands = _normalizedAgeBands(targetAgeBands) {
    if (priority < 0 || priority > 100) {
      throw ArgumentError.value(priority, 'priority', 'must be between 0 and 100');
    }
    if (freshnessWindowDays < 1 || freshnessWindowDays > 90) {
      throw ArgumentError.value(
        freshnessWindowDays,
        'freshnessWindowDays',
        'must be between 1 and 90',
      );
    }
  }

  final String id;
  final String text;
  final String intent;
  final int priority;
  final int freshnessWindowDays;
  final List<String> targetAgeBands;
  final bool regionScoped;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'text': text,
      'intent': intent,
      'priority': priority,
      'freshnessWindowDays': freshnessWindowDays,
      if (targetAgeBands.isNotEmpty) 'targetAgeBands': targetAgeBands,
      'regionScoped': regionScoped,
    };
  }

  static String _validatedId(String value) {
    final normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{2,63}$').hasMatch(normalized)) {
      throw ArgumentError.value(value, 'id', 'must be a stable lowercase identifier');
    }
    return normalized;
  }

  static String _validatedText(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > 120) {
      throw ArgumentError.value(value, 'text', 'must contain 1 to 120 characters');
    }
    return normalized;
  }

  static String _validatedIntent(String value) {
    final normalized = value.trim().toLowerCase();
    if (!DailyQueryIntents.allowed.contains(normalized)) {
      throw ArgumentError.value(value, 'intent', 'is not supported');
    }
    return normalized;
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
}

final class DailyQueryPlanRequest {
  DailyQueryPlanRequest({
    required DateTime date,
    required String locale,
    String regionCode = 'global',
    String? regionLabel,
    Iterable<String> targetAgeBands = const [],
  }) : date = DateTime.utc(date.year, date.month, date.day),
       locale = _validatedText(locale, 'locale', 32),
       regionCode = _validatedText(regionCode, 'regionCode', 120),
       regionLabel = _optionalText(regionLabel, 'regionLabel', 60),
       targetAgeBands = DailySearchQuery._normalizedAgeBands(targetAgeBands) {
    if (this.regionCode.toLowerCase() == 'global' && this.regionLabel != null) {
      throw ArgumentError(
        'regionLabel requires a non-global regionCode so local material is not stored as global.',
      );
    }
  }

  final DateTime date;
  final String locale;
  final String regionCode;
  final String? regionLabel;
  final List<String> targetAgeBands;

  static String _validatedText(String value, String name, int maximumLength) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > maximumLength) {
      throw ArgumentError.value(
        value,
        name,
        'must contain 1 to $maximumLength characters',
      );
    }
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(normalized)) {
      throw ArgumentError.value(value, name, 'must not contain control characters');
    }
    return normalized;
  }

  static String? _optionalText(String? value, String name, int maximumLength) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return _validatedText(trimmed, name, maximumLength);
  }
}

final class DailyQueryPlan {
  DailyQueryPlan({
    required this.request,
    required Iterable<DailySearchQuery> queries,
  }) : queries = List.unmodifiable(queries);

  final DailyQueryPlanRequest request;
  final List<DailySearchQuery> queries;

  Map<String, Object?> toJson() {
    return {
      'date': _formatDate(request.date),
      'locale': request.locale,
      'regionCode': request.regionCode,
      if (request.regionLabel != null) 'regionLabel': request.regionLabel,
      if (request.targetAgeBands.isNotEmpty)
        'targetAgeBands': request.targetAgeBands,
      'queries': queries.map((query) => query.toJson()).toList(),
    };
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
