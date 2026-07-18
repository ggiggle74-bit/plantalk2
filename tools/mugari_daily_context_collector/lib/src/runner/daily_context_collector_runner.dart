import '../composition/daily_keyword_context_assembler.dart';
import '../extraction/daily_keyword_extraction_policy.dart';
import '../models/daily_keyword_candidate.dart';
import '../models/daily_keyword_context_document.dart';
import '../models/search_document.dart';
import '../planning/daily_query_planner.dart';
import '../planning/daily_search_query.dart';
import '../sources/daily_candidate_source.dart';
import '../sources/local_calendar_season_source.dart';

enum DailyCollectorRunStatus {
  success('SUCCESS'),
  empty('EMPTY'),
  sourceFailed('SOURCE_FAILED');

  const DailyCollectorRunStatus(this.wireName);

  final String wireName;
}

abstract interface class SearchDocumentLoader {
  Future<List<SearchDocument>> load(DailySearchQuery query);
}

final class DailyCollectorRunRequest {
  DailyCollectorRunRequest({
    required DateTime date,
    required String locale,
    required String regionCode,
    required DateTime generatedAt,
    required String sourceVersion,
    String? regionLabel,
    Iterable<String> targetAgeBands = const [],
  }) : date = DateTime.utc(date.year, date.month, date.day),
       locale = locale.trim(),
       regionCode = regionCode.trim(),
       generatedAt = generatedAt.toUtc(),
       sourceVersion = sourceVersion.trim(),
       regionLabel = _optionalText(regionLabel),
       targetAgeBands = List.unmodifiable(targetAgeBands);

  final DateTime date;
  final String locale;
  final String regionCode;
  final DateTime generatedAt;
  final String sourceVersion;
  final String? regionLabel;
  final List<String> targetAgeBands;

  static String? _optionalText(String? value) {
    final normalized = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

final class DailyCollectorRunReport {
  DailyCollectorRunReport({
    required this.status,
    required this.document,
    required Iterable<String> failedQueryIds,
    required Iterable<String> failedCandidateSourceIds,
    required this.searchDocumentCount,
    required this.extractedCandidateCount,
    required this.blockedDocumentCount,
    required this.staleDocumentCount,
    required this.unmatchedDocumentCount,
  }) : failedQueryIds = List.unmodifiable(failedQueryIds),
       failedCandidateSourceIds = List.unmodifiable(
         failedCandidateSourceIds,
       );

  final DailyCollectorRunStatus status;
  final DailyKeywordContextDocument document;
  final List<String> failedQueryIds;
  final List<String> failedCandidateSourceIds;
  final int searchDocumentCount;
  final int extractedCandidateCount;
  final int blockedDocumentCount;
  final int staleDocumentCount;
  final int unmatchedDocumentCount;

  bool get isDegraded =>
      failedQueryIds.isNotEmpty || failedCandidateSourceIds.isNotEmpty;

  Map<String, Object?> toSummaryJson() {
    return {
      'status': status.wireName,
      'date': _date(document.date),
      'regionCode': document.regionCode,
      'keywordCount': document.keywords.length,
      'searchDocumentCount': searchDocumentCount,
      'extractedCandidateCount': extractedCandidateCount,
      'blockedDocumentCount': blockedDocumentCount,
      'staleDocumentCount': staleDocumentCount,
      'unmatchedDocumentCount': unmatchedDocumentCount,
      'failedQueryIds': failedQueryIds,
      'failedCandidateSourceIds': failedCandidateSourceIds,
      'degraded': isDegraded,
    };
  }

  static String _date(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

final class DailyContextCollectorRunner {
  DailyContextCollectorRunner({
    required SearchDocumentLoader searchLoader,
    DailyQueryPlanner queryPlanner = const DailyQueryPlanner(),
    DailyKeywordExtractionPolicy extractionPolicy =
        const DailyKeywordExtractionPolicy(),
    Iterable<DailyCandidateSource> localSources = const [
      LocalCalendarSeasonSource(),
    ],
  }) : _searchLoader = searchLoader,
       _queryPlanner = queryPlanner,
       _extractionPolicy = extractionPolicy,
       _localSources = List.unmodifiable(localSources);

  final SearchDocumentLoader _searchLoader;
  final DailyQueryPlanner _queryPlanner;
  final DailyKeywordExtractionPolicy _extractionPolicy;
  final List<DailyCandidateSource> _localSources;

  Future<DailyCollectorRunReport> run(
    DailyCollectorRunRequest request,
  ) async {
    final plan = _queryPlanner.plan(
      DailyQueryPlanRequest(
        date: request.date,
        locale: request.locale,
        regionCode: request.regionCode,
        regionLabel: request.regionLabel,
        targetAgeBands: request.targetAgeBands,
      ),
    );

    final documents = <SearchDocument>[];
    final failedQueryIds = <String>[];
    for (final query in plan.queries) {
      try {
        final loaded = await _searchLoader.load(query);
        if (loaded.any((document) => document.queryId != query.id)) {
          throw StateError(
            'search loader returned a document for another query',
          );
        }
        documents.addAll(loaded);
      } on Object {
        failedQueryIds.add(query.id);
      }
    }

    final extraction = _extractionPolicy.extract(
      date: request.date,
      documents: documents,
    );
    final candidateSources = <DailyCandidateSource>[
      ..._localSources,
      SnapshotDailyCandidateSource(
        id: 'search-extraction',
        candidates: extraction.candidates,
      ),
    ];
    final assembly = await DailyKeywordContextAssembler(
      sources: candidateSources,
    ).assemble(
      DailyContextAssemblyRequest(
        date: request.date,
        locale: request.locale,
        regionCode: request.regionCode,
        generatedAt: request.generatedAt,
        sourceVersion: request.sourceVersion,
      ),
    );

    final status = _statusFor(
      totalQueryCount: plan.queries.length,
      failedQueryCount: failedQueryIds.length,
      extractedCandidateCount: extraction.candidates.length,
    );

    return DailyCollectorRunReport(
      status: status,
      document: assembly.document,
      failedQueryIds: failedQueryIds,
      failedCandidateSourceIds: assembly.failedSourceIds,
      searchDocumentCount: documents.length,
      extractedCandidateCount: extraction.candidates.length,
      blockedDocumentCount: extraction.blockedDocumentCount,
      staleDocumentCount: extraction.staleDocumentCount,
      unmatchedDocumentCount: extraction.unmatchedDocumentCount,
    );
  }

  DailyCollectorRunStatus _statusFor({
    required int totalQueryCount,
    required int failedQueryCount,
    required int extractedCandidateCount,
  }) {
    if (totalQueryCount > 0 && failedQueryCount == totalQueryCount) {
      return DailyCollectorRunStatus.sourceFailed;
    }
    if (extractedCandidateCount > 0) {
      return DailyCollectorRunStatus.success;
    }
    if (failedQueryCount > 0) {
      return DailyCollectorRunStatus.sourceFailed;
    }
    return DailyCollectorRunStatus.empty;
  }
}
