import '../models/daily_keyword_candidate.dart';
import '../models/daily_keyword_context_document.dart';
import '../sources/daily_candidate_source.dart';
import '../validation/daily_keyword_contract_validator.dart';

final class DailyContextAssemblyRequest {
  DailyContextAssemblyRequest({
    required DateTime date,
    required String locale,
    required String regionCode,
    required DateTime generatedAt,
    required String sourceVersion,
  }) : date = DateTime.utc(date.year, date.month, date.day),
       locale = _text(locale, 'locale', 32),
       regionCode = _text(regionCode, 'regionCode', 120),
       generatedAt = generatedAt.toUtc(),
       sourceVersion = _text(sourceVersion, 'sourceVersion', 64);

  final DateTime date;
  final String locale;
  final String regionCode;
  final DateTime generatedAt;
  final String sourceVersion;

  DailyCandidateSourceRequest get sourceRequest {
    return DailyCandidateSourceRequest(
      date: date,
      locale: locale,
      regionCode: regionCode,
    );
  }

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

final class DailyContextAssemblyResult {
  DailyContextAssemblyResult({
    required this.document,
    required Iterable<String> failedSourceIds,
    required this.rejectedCandidateCount,
  }) : failedSourceIds = List.unmodifiable(failedSourceIds);

  final DailyKeywordContextDocument document;
  final List<String> failedSourceIds;
  final int rejectedCandidateCount;
}

final class DailyKeywordContextAssembler {
  DailyKeywordContextAssembler({
    required Iterable<DailyCandidateSource> sources,
    this.maximumCandidates = 8,
    this.maximumPerType = 3,
    DailyKeywordContractValidator validator =
        const DailyKeywordContractValidator(),
  }) : sources = List.unmodifiable(sources),
       _validator = validator {
    final ids = <String>{};
    for (final source in this.sources) {
      if (!ids.add(source.id)) {
        throw ArgumentError('daily candidate source IDs must be unique');
      }
    }
  }

  final List<DailyCandidateSource> sources;
  final int maximumCandidates;
  final int maximumPerType;
  final DailyKeywordContractValidator _validator;

  Future<DailyContextAssemblyResult> assemble(
    DailyContextAssemblyRequest request,
  ) async {
    if (maximumCandidates < 1 || maximumCandidates > 8) {
      throw StateError('maximumCandidates must be between 1 and 8.');
    }
    if (maximumPerType < 1 || maximumPerType > maximumCandidates) {
      throw StateError(
        'maximumPerType must be between 1 and maximumCandidates.',
      );
    }

    final failedSourceIds = <String>[];
    final collected = <DailyKeywordCandidate>[];
    for (final source in sources) {
      try {
        collected.addAll(await source.load(request.sourceRequest));
      } on Object {
        failedSourceIds.add(source.id);
      }
    }

    final bestByKey = <String, DailyKeywordCandidate>{};
    var rejectedCount = 0;
    for (final candidate in collected) {
      if (!_isIndividuallyValid(candidate, request)) {
        rejectedCount++;
        continue;
      }
      final key =
          '${candidate.type}|${_normalize(candidate.keyword)}';
      final existing = bestByKey[key];
      if (existing == null || _compareQuality(candidate, existing) > 0) {
        bestByKey[key] = candidate;
      }
    }

    final ranked = bestByKey.values.toList()
      ..sort((left, right) {
        final quality = _compareQuality(right, left);
        if (quality != 0) {
          return quality;
        }
        final typeOrder = _typePriority(left.type).compareTo(
          _typePriority(right.type),
        );
        if (typeOrder != 0) {
          return typeOrder;
        }
        return left.keyword.compareTo(right.keyword);
      });

    final selected = <DailyKeywordCandidate>[];
    final typeCounts = <String, int>{};
    for (final candidate in ranked) {
      final count = typeCounts[candidate.type] ?? 0;
      if (count >= maximumPerType) {
        continue;
      }
      selected.add(candidate);
      typeCounts[candidate.type] = count + 1;
      if (selected.length == maximumCandidates) {
        break;
      }
    }

    final document = DailyKeywordContextDocument(
      date: request.date,
      locale: request.locale,
      regionCode: request.regionCode,
      generatedAt: request.generatedAt,
      sourceVersion: request.sourceVersion,
      keywords: selected,
    );
    _validator.validate(document).throwIfInvalid();

    return DailyContextAssemblyResult(
      document: document,
      failedSourceIds: failedSourceIds,
      rejectedCandidateCount: rejectedCount,
    );
  }

  bool _isIndividuallyValid(
    DailyKeywordCandidate candidate,
    DailyContextAssemblyRequest request,
  ) {
    final probe = DailyKeywordContextDocument(
      date: request.date,
      locale: request.locale,
      regionCode: request.regionCode,
      generatedAt: request.generatedAt,
      sourceVersion: request.sourceVersion,
      keywords: [candidate],
    );
    return _validator.validate(probe).isValid;
  }

  int _compareQuality(
    DailyKeywordCandidate left,
    DailyKeywordCandidate right,
  ) {
    final relevance = (left.relevanceScore ?? left.fitScore).compareTo(
      right.relevanceScore ?? right.fitScore,
    );
    if (relevance != 0) {
      return relevance;
    }
    return left.fitScore.compareTo(right.fitScore);
  }

  int _typePriority(String type) {
    return switch (type) {
      DailyKeywordTypes.calendar => 0,
      DailyKeywordTypes.weather => 1,
      DailyKeywordTypes.seasonal => 2,
      DailyKeywordTypes.safeIssue => 3,
      _ => 4,
    };
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
