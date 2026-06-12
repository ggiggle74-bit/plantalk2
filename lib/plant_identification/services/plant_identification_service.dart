import '../adapters/plant_identification_adapter.dart';
import '../models/plant_identification_input.dart';
import '../models/plant_identification_result.dart';
import '../normalizers/plant_identification_normalizer.dart';

/// Orchestrates candidate identification only; user choice happens elsewhere.
class PlantIdentificationService {
  const PlantIdentificationService({
    required PlantIdentificationAdapter adapter,
    PlantIdentificationNormalizer normalizer =
        const PlantIdentificationNormalizer(),
  }) : _adapter = adapter,
       _normalizer = normalizer;

  final PlantIdentificationAdapter _adapter;
  final PlantIdentificationNormalizer _normalizer;

  Future<PlantIdentificationResult> identify(
    PlantIdentificationInput input,
  ) async {
    final result = await _adapter.identify(input);

    return _normalizer.normalize(result);
  }
}
