import 'plant_identification_candidate.dart';

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
  final Map<String, dynamic> metadata;
}
