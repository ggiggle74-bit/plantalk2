/// One possible plant identity option returned from photo identification.
///
/// Candidates are options for the user to review; they do not confirm identity.
class PlantIdentificationCandidate {
  const PlantIdentificationCandidate({
    required this.displayName,
    required this.source,
    required this.candidateRank,
    this.scientificName,
    this.commonNames = const <String>[],
    this.confidence,
    this.rawId,
    this.metadata = const <String, dynamic>{},
  });

  final String displayName;
  final String? scientificName;
  final List<String> commonNames;
  final double? confidence;
  final String source;
  final int candidateRank;
  final String? rawId;

  /// Safe normalized metadata only. Do not store raw provider/API payloads.
  final Map<String, dynamic> metadata;
}
