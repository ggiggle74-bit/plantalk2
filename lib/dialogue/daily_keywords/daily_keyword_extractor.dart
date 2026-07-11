import 'catalogs/blocked_keyword_catalog.dart';
import 'models/daily_keyword_candidate.dart';
import 'models/daily_keyword_extraction_result.dart';

class DailyKeywordExtractor {
  const DailyKeywordExtractor({
    this.minimumFitScore = 0.60,
    this.sourceVersion = 'cr1-static-v1',
  });

  final double minimumFitScore;
  final String sourceVersion;

  DailyKeywordExtractionResult extract(
    Iterable<DailyKeywordCandidate> candidates,
  ) {
    final acceptedCandidates = <DailyKeywordCandidate>[];
    final candidateKeys = <String>{};
    var rejectedCount = 0;

    for (final candidate in candidates) {
      final key =
          '${_normalize(candidate.type)}|${_normalize(candidate.keyword)}';
      if (!_isValid(candidate) || !candidateKeys.add(key)) {
        rejectedCount++;
        continue;
      }
      acceptedCandidates.add(candidate);
    }

    return DailyKeywordExtractionResult(
      acceptedCandidates: acceptedCandidates,
      rejectedCount: rejectedCount,
      sourceVersion: sourceVersion,
    );
  }

  bool _isValid(DailyKeywordCandidate candidate) {
    final type = _normalize(candidate.type);
    final tone = _normalize(candidate.tone);
    return DailyKeywordTypes.allowed.contains(type) &&
        candidate.keyword.trim().isNotEmpty &&
        candidate.hint.trim().isNotEmpty &&
        candidate.plantHint.trim().isNotEmpty &&
        DailyKeywordTones.allowed.contains(tone) &&
        candidate.fitScore.isFinite &&
        candidate.fitScore >= 0.0 &&
        candidate.fitScore <= 1.0 &&
        candidate.fitScore >= minimumFitScore &&
        !BlockedKeywordCatalog.blocks(candidate);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
