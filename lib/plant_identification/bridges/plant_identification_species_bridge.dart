import '../../photo/supported_species.dart';
import '../models/plant_identification_candidate.dart';
import 'plant_identification_korean_name_bridge.dart';

SupportedSpecies supportedSpeciesFromPlantIdentificationCandidate(
  PlantIdentificationCandidate candidate,
) {
  return SupportedSpecies(
    key: _candidateSpeciesKey(candidate),
    displayName: displayNameFromPlantIdentificationCandidate(candidate),
    aliases: [
      if (_hasText(candidate.scientificName)) candidate.scientificName!.trim(),
      ...candidate.commonNames
          .where(_hasText)
          .map((commonName) => commonName.trim()),
    ],
  );
}

String _candidateSpeciesKey(PlantIdentificationCandidate candidate) {
  final scientificName = candidate.scientificName?.trim();
  if (_hasText(scientificName)) {
    return scientificName!.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  final rawId = candidate.rawId?.trim();
  if (_hasText(rawId)) {
    return rawId!;
  }

  return candidate.displayName.trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    '_',
  );
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}
