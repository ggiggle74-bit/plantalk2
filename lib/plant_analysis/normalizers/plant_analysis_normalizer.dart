import '../models/external_plant_analysis_result.dart';
import '../models/normalized_plant_event.dart';

class PlantAnalysisNormalizer {
  const PlantAnalysisNormalizer();

  List<NormalizedPlantEvent> normalize(ExternalPlantAnalysisResult result) {
    if (result.conditionEventHints.isEmpty) {
      return [
        _eventFromResult(
          result,
          eventType: PlantAnalysisEventTypes.conditionUncertain,
        ),
      ];
    }

    return result.conditionEventHints
        .map(
          (hint) => _eventFromResult(
            result,
            eventType: PlantAnalysisEventTypes.normalize(hint.eventType),
            confidence: hint.confidence,
            message: hint.note,
          ),
        )
        .toList(growable: false);
  }

  NormalizedPlantEvent _eventFromResult(
    ExternalPlantAnalysisResult result, {
    required String eventType,
    double? confidence,
    String? message,
  }) {
    return NormalizedPlantEvent(
      eventType: eventType,
      sourceProvider: result.providerKey,
      confidence: confidence,
      message: message,
      observedAt: result.createdAt,
      sourceResultId: result.providerResultId,
      isMock: result.isMock,
      metadata: {'analysisType': result.analysisType},
    );
  }
}
