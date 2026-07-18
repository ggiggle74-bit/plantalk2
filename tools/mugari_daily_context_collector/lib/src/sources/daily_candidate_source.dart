import '../models/daily_keyword_candidate.dart';

final class DailyCandidateSourceRequest {
  DailyCandidateSourceRequest({
    required DateTime date,
    required String locale,
    required String regionCode,
  }) : date = DateTime.utc(date.year, date.month, date.day),
       locale = _text(locale, 'locale', 32),
       regionCode = _text(regionCode, 'regionCode', 120);

  final DateTime date;
  final String locale;
  final String regionCode;

  static String _text(String value, String name, int maximumLength) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > maximumLength) {
      throw ArgumentError.value(
        value,
        name,
        'must contain 1 to $maximumLength characters',
      );
    }
    return normalized;
  }
}

abstract interface class DailyCandidateSource {
  String get id;

  Future<List<DailyKeywordCandidate>> load(
    DailyCandidateSourceRequest request,
  );
}

final class SnapshotDailyCandidateSource implements DailyCandidateSource {
  SnapshotDailyCandidateSource({
    required String id,
    required Iterable<DailyKeywordCandidate> candidates,
  }) : id = _validatedId(id),
       _candidates = List.unmodifiable(candidates);

  @override
  final String id;
  final List<DailyKeywordCandidate> _candidates;

  @override
  Future<List<DailyKeywordCandidate>> load(
    DailyCandidateSourceRequest request,
  ) async {
    return List.unmodifiable(_candidates);
  }

  static String _validatedId(String value) {
    final normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{2,63}$').hasMatch(normalized)) {
      throw ArgumentError.value(value, 'id', 'must be a stable identifier');
    }
    return normalized;
  }
}
