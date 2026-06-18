import '../models/plant_identification_candidate.dart';
import 'plant_korean_name_catalog.dart';

PlantKoreanNameEntry? koreanNameEntryFromPlantIdentificationCandidate(
  PlantIdentificationCandidate candidate,
) {
  return findPlantKoreanNameEntry(
    scientificName: candidate.scientificName,
    displayName: candidate.displayName,
    commonNames: candidate.commonNames,
  );
}

String displayNameFromPlantIdentificationCandidate(
  PlantIdentificationCandidate candidate,
) {
  final entry = koreanNameEntryFromPlantIdentificationCandidate(candidate);
  if (_hasText(entry?.koreanName)) {
    return entry!.koreanName.trim();
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
