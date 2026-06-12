import 'plant_identification_candidate.dart';

/// Candidate plant identity options for user selection or manual entry.
///
/// This result must not create a Plant or automatically confirm identity.
class PlantIdentificationResult {
  const PlantIdentificationResult({
    required this.providerKey,
    required this.candidates,
    required this.isMock,
    required this.observedAt,
    this.sourceResultId,
    this.metadata = const <String, dynamic>{},
  });

  final String providerKey;
  final List<PlantIdentificationCandidate> candidates;
  final bool isMock;
  final String? sourceResultId;
  final DateTime observedAt;

  /// Safe normalized metadata only. Do not store raw provider/API payloads.
  final Map<String, dynamic> metadata;
}
