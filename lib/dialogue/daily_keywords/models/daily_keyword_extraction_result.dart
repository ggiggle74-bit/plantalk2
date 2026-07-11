import 'daily_keyword_candidate.dart';

class DailyKeywordExtractionResult {
  DailyKeywordExtractionResult({
    required List<DailyKeywordCandidate> acceptedCandidates,
    required this.rejectedCount,
    required this.sourceVersion,
  }) : acceptedCandidates = List.unmodifiable(acceptedCandidates);

  final List<DailyKeywordCandidate> acceptedCandidates;
  final int rejectedCount;
  final String sourceVersion;

  bool get hasCandidates => acceptedCandidates.isNotEmpty;
}
