import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_identification/bridges/plant_identification_korean_name_bridge.dart';
import 'package:plantalk2/plant_identification/bridges/plant_identification_species_bridge.dart';
import 'package:plantalk2/plant_identification/models/plant_identification_candidate.dart';

void main() {
  group('displayNameFromPlantIdentificationCandidate', () {
    test('maps authored Monstera deliciosa scientific name to Korean name', () {
      final candidate = _candidate(
        displayName: 'Swiss cheese plant',
        scientificName: 'Monstera deliciosa L.',
      );

      expect(
        displayNameFromPlantIdentificationCandidate(candidate),
        '몬스테라 델리시오사',
      );
    });

    test('maps Epipremnum aureum scientific name to Korean name', () {
      final candidate = _candidate(
        displayName: 'pothos',
        scientificName: 'Epipremnum aureum',
      );

      expect(displayNameFromPlantIdentificationCandidate(candidate), '스킨답서스');
    });

    test('maps generic Monstera to generic Korean name', () {
      final candidate = _candidate(displayName: 'Monstera');

      expect(displayNameFromPlantIdentificationCandidate(candidate), '몬스테라');
    });

    test('preserves original display name for unknown candidates', () {
      final candidate = _candidate(
        displayName: 'Slender amaranth',
        scientificName: 'Amaranthus viridis L.',
      );

      expect(
        displayNameFromPlantIdentificationCandidate(candidate),
        'Slender amaranth',
      );
    });
  });

  group('supportedSpeciesFromPlantIdentificationCandidate', () {
    test(
      'uses Korean display name without changing generated key or aliases',
      () {
        final candidate = _candidate(
          displayName: 'pothos',
          scientificName: 'Epipremnum aureum',
          commonNames: ['pothos'],
        );

        final species = supportedSpeciesFromPlantIdentificationCandidate(
          candidate,
        );

        expect(species.key, 'epipremnum_aureum');
        expect(species.displayName, '스킨답서스');
        expect(species.aliases, ['Epipremnum aureum', 'pothos']);
      },
    );
  });
}

PlantIdentificationCandidate _candidate({
  required String displayName,
  String? scientificName,
  List<String> commonNames = const <String>[],
}) {
  return PlantIdentificationCandidate(
    displayName: displayName,
    scientificName: scientificName,
    commonNames: commonNames,
    source: 'plantnet',
    candidateRank: 1,
  );
}
