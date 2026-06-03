import '../adapters/plant_analysis_adapter.dart';
import '../models/external_plant_analysis_result.dart';
import '../models/normalized_plant_event.dart';
import '../models/plant_analysis_input.dart';
import '../normalizers/plant_analysis_normalizer.dart';

class PlantAnalysisService {
  const PlantAnalysisService({
    required PlantAnalysisAdapter adapter,
    PlantAnalysisNormalizer normalizer = const PlantAnalysisNormalizer(),
  }) : _adapter = adapter,
       _normalizer = normalizer;

  final PlantAnalysisAdapter _adapter;
  final PlantAnalysisNormalizer _normalizer;

  Future<PlantAnalysisServiceResult> analyze(PlantAnalysisInput input) async {
    final externalResult = await _adapter.analyze(input);
    final events = _normalizer.normalize(externalResult);

    return PlantAnalysisServiceResult(
      externalResult: externalResult,
      normalizedEvents: events,
    );
  }
}

class PlantAnalysisServiceResult {
  const PlantAnalysisServiceResult({
    required this.externalResult,
    required this.normalizedEvents,
  });

  final ExternalPlantAnalysisResult externalResult;
  final List<NormalizedPlantEvent> normalizedEvents;
}
