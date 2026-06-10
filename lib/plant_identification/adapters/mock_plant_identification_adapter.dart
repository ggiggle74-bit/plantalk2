import '../models/plant_identification_candidate.dart';
import '../models/plant_identification_input.dart';
import '../models/plant_identification_result.dart';
import 'plant_identification_adapter.dart';

class MockPlantIdentificationAdapter implements PlantIdentificationAdapter {
  const MockPlantIdentificationAdapter();

  @override
  String get providerKey => 'mock_plant_identification';

  @override
  Future<PlantIdentificationResult> identify(
    PlantIdentificationInput input,
  ) async {
    return PlantIdentificationResult(
      providerKey: providerKey,
      candidates: [
        PlantIdentificationCandidate(
          displayName: '스킨답서스',
          scientificName: 'Epipremnum aureum',
          commonNames: const ['Golden pothos'],
          confidence: 0.78,
          source: providerKey,
          candidateRank: 1,
          rawId: 'mock-epipremnum-aureum',
        ),
        PlantIdentificationCandidate(
          displayName: '필로덴드론',
          scientificName: 'Philodendron hederaceum',
          commonNames: const ['Heartleaf philodendron'],
          confidence: 0.62,
          source: providerKey,
          candidateRank: 2,
          rawId: 'mock-philodendron-hederaceum',
        ),
        PlantIdentificationCandidate(
          displayName: '몬스테라',
          scientificName: 'Monstera deliciosa',
          commonNames: const ['Swiss cheese plant'],
          confidence: 0.49,
          source: providerKey,
          candidateRank: 3,
          rawId: 'mock-monstera-deliciosa',
        ),
      ],
      isMock: true,
      observedAt: input.requestedAt,
      metadata: const {'boundary': 'plant_identification'},
    );
  }
}
