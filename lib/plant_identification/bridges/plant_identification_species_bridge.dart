import '../../photo/supported_species.dart';
import '../models/plant_identification_candidate.dart';
import 'plant_identification_korean_name_bridge.dart';
import 'plant_korean_name_catalog.dart';

SupportedSpecies supportedSpeciesFromPlantIdentificationCandidate(
  PlantIdentificationCandidate candidate,
) {
  final catalogEntry = koreanNameEntryFromPlantIdentificationCandidate(
    candidate,
  );

  return SupportedSpecies(
    key: _candidateSpeciesKey(candidate, catalogEntry),
    displayName: _candidateDisplayName(candidate, catalogEntry),
    aliases: [
      if (_hasText(candidate.scientificName)) candidate.scientificName!.trim(),
      ...candidate.commonNames
          .where(_hasText)
          .map((commonName) => commonName.trim()),
    ],
  );
}

String _candidateSpeciesKey(
  PlantIdentificationCandidate candidate,
  PlantKoreanNameEntry? catalogEntry,
) {
  final supportedSpeciesKey = catalogEntry?.supportedSpeciesKey?.trim();
  if (_hasText(supportedSpeciesKey)) {
    return supportedSpeciesKey!;
  }

  final catalogKey = catalogEntry?.key.trim();
  if (_hasText(catalogKey)) {
    return catalogKey!;
  }

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

String _candidateDisplayName(
  PlantIdentificationCandidate candidate,
  PlantKoreanNameEntry? catalogEntry,
) {
  final koreanName = catalogEntry?.koreanName.trim();
  if (_hasText(koreanName)) {
    return koreanName!;
  }

  if (_hasText(candidate.displayName)) {
    return candidate.displayName.trim();
  }

  if (_hasText(candidate.scientificName)) {
    return candidate.scientificName!.trim();
  }

  return '알 수 없는 식물';
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}
