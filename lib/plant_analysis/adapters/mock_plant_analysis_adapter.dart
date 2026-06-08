import '../models/external_plant_analysis_result.dart';
import '../models/normalized_plant_event.dart';
import '../models/plant_analysis_input.dart';
import 'plant_analysis_adapter.dart';

class MockPlantAnalysisAdapter implements PlantAnalysisAdapter {
  const MockPlantAnalysisAdapter({
    this.mockEventType = PlantAnalysisEventTypes.conditionUncertain,
    this.mockNote = 'Mock adapter output for boundary testing only.',
  });

  @override
  String get providerKey => 'mock_plant_analysis';

  final String mockEventType;
  final String mockNote;

  @override
  Future<ExternalPlantAnalysisResult> analyze(PlantAnalysisInput input) async {
    final eventType = PlantAnalysisEventTypes.normalize(mockEventType);

    return ExternalPlantAnalysisResult(
      providerKey: providerKey,
      analysisType: input.analysisType,
      conditionEventHints: [
        ExternalPlantConditionEventHint(
          eventType: eventType,
          confidence: eventType == PlantAnalysisEventTypes.conditionUncertain
              ? 0.3
              : 0.7,
          note: mockNote,
        ),
      ],
      summary: 'Mock plant analysis result. Do not use as direct dialogue.',
      rawPayload: {
        'mock': true,
        'analysisType': input.analysisType,
        'plantId': input.plantId,
      },
      isMock: true,
      createdAt: input.requestedAt ?? DateTime.now(),
    );
  }
}
