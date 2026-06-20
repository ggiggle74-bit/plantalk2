import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_identification/bridges/plant_identification_korean_name_bridge.dart';
import 'package:plantalk2/plant_identification/bridges/plant_identification_species_bridge.dart';
import 'package:plantalk2/plant_identification/bridges/plant_korean_name_catalog.dart';
import 'package:plantalk2/plant_identification/models/plant_identification_candidate.dart';
import 'package:plantalk2/photo/supported_species.dart';

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
      'uses supported species key for existing supported-species mapping',
      () {
        final candidate = _candidate(
          displayName: 'pothos',
          scientificName: 'Epipremnum aureum',
          commonNames: ['pothos'],
        );

        final species = supportedSpeciesFromPlantIdentificationCandidate(
          candidate,
        );

        expect(species.key, 'pothos');
        expect(species.displayName, '스킨답서스');
        expect(species.aliases, ['Epipremnum aureum', 'pothos']);
      },
    );

    test('uses catalog key for authored scientific-name suffix matches', () {
      final candidate = _candidate(
        displayName: 'Swiss cheese plant',
        scientificName: 'Monstera deliciosa L.',
      );

      final species = supportedSpeciesFromPlantIdentificationCandidate(
        candidate,
      );

      expect(species.key, 'monstera_deliciosa');
      expect(species.key, isNot('monstera_deliciosa_l.'));
      expect(species.displayName, '몬스테라 델리시오사');
    });

    test('prefers explicit supported species category mapping', () {
      final candidate = _candidate(
        displayName: 'Fiddle leaf fig',
        scientificName: 'Ficus lyrata',
      );

      final species = supportedSpeciesFromPlantIdentificationCandidate(
        candidate,
      );

      expect(species.key, 'rubber_tree');
      expect(species.displayName, '떡갈고무나무');
    });

    test('uses catalog-only stable key when category mapping is absent', () {
      final candidate = _candidate(
        displayName: 'rosemary',
        scientificName: 'Salvia rosmarinus',
      );

      final species = supportedSpeciesFromPlantIdentificationCandidate(
        candidate,
      );

      expect(species.key, 'rosemary');
      expect(species.displayName, '로즈마리');
    });

    test('keeps scientific-name fallback for catalog misses', () {
      final candidate = _candidate(
        displayName: 'Common garden petunia',
        scientificName: 'Petunia atkinsiana',
      );

      final species = supportedSpeciesFromPlantIdentificationCandidate(
        candidate,
      );

      expect(species.key, 'petunia_atkinsiana');
      expect(species.displayName, 'Common garden petunia');
    });

    test(
      'keeps rawId fallback when no scientific name or catalog match exists',
      () {
        final candidate = _candidate(
          displayName: 'Unlisted mystery plant',
          rawId: 'provider-raw-123',
        );

        final species = supportedSpeciesFromPlantIdentificationCandidate(
          candidate,
        );

        expect(species.key, 'provider-raw-123');
        expect(species.displayName, 'Unlisted mystery plant');
      },
    );

    test('catalog supported species mappings point to existing categories', () {
      final supportedSpeciesKeys = supportedSpecies
          .map((species) => species.key)
          .toSet();

      for (final entry in plantKoreanNameCatalog) {
        final supportedSpeciesKey = entry.supportedSpeciesKey?.trim();
        if (supportedSpeciesKey == null || supportedSpeciesKey.isEmpty) {
          continue;
        }

        expect(
          supportedSpeciesKeys,
          contains(supportedSpeciesKey),
          reason: '${entry.key} maps to missing $supportedSpeciesKey',
        );
      }
    });
  });
}

PlantIdentificationCandidate _candidate({
  required String displayName,
  String? scientificName,
  List<String> commonNames = const <String>[],
  String? rawId,
}) {
  return PlantIdentificationCandidate(
    displayName: displayName,
    scientificName: scientificName,
    commonNames: commonNames,
    source: 'plantnet',
    candidateRank: 1,
    rawId: rawId,
  );
}
