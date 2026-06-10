import '../models/plant_identification_candidate.dart';
import '../models/plant_identification_result.dart';

class PlantIdentificationNormalizer {
  const PlantIdentificationNormalizer();

  PlantIdentificationResult normalize(PlantIdentificationResult result) {
    final candidates = result.candidates
        .where((candidate) => candidate.displayName.trim().isNotEmpty)
        .map(_withoutProviderMetadata)
        .toList(growable: false);

    final sortedCandidates = [...candidates]
      ..sort((left, right) {
        final rankComparison = left.candidateRank.compareTo(
          right.candidateRank,
        );
        if (rankComparison != 0) {
          return rankComparison;
        }

        final leftConfidence = left.confidence;
        final rightConfidence = right.confidence;
        if (leftConfidence == null && rightConfidence == null) {
          return 0;
        }
        if (leftConfidence == null) {
          return 1;
        }
        if (rightConfidence == null) {
          return -1;
        }

        return rightConfidence.compareTo(leftConfidence);
      });

    return PlantIdentificationResult(
      providerKey: result.providerKey,
      candidates: sortedCandidates,
      isMock: result.isMock,
      sourceResultId: result.sourceResultId,
      observedAt: result.observedAt,
      metadata: const <String, dynamic>{},
    );
  }

  PlantIdentificationCandidate _withoutProviderMetadata(
    PlantIdentificationCandidate candidate,
  ) {
    return PlantIdentificationCandidate(
      displayName: candidate.displayName.trim(),
      scientificName: candidate.scientificName,
      commonNames: candidate.commonNames,
      confidence: candidate.confidence,
      source: candidate.source,
      candidateRank: candidate.candidateRank,
      rawId: candidate.rawId,
      metadata: const <String, dynamic>{},
    );
  }
}
