import 'package:image_picker/image_picker.dart';

import 'plant_condition_analysis_service.dart';
import 'plant_service.dart';
import 'plant_photo_flow_service.dart';

class PlantConditionCheckFlowResult {
  const PlantConditionCheckFlowResult({
    required this.photoUrl,
    required this.analysisResult,
  });

  final String photoUrl;
  final PlantConditionAnalysisResult analysisResult;
}

class PlantConditionCheckFlowService {
  PlantConditionCheckFlowService({
    required PlantPhotoFlowService plantPhotoFlowService,
    required PlantConditionAnalysisService conditionAnalysisService,
    required PlantService plantService,
  }) : _plantPhotoFlowService = plantPhotoFlowService,
       _conditionAnalysisService = conditionAnalysisService,
       _plantService = plantService;

  final PlantPhotoFlowService _plantPhotoFlowService;
  final PlantConditionAnalysisService _conditionAnalysisService;
  final PlantService _plantService;

  Future<PlantConditionCheckFlowResult> checkCondition({
    required XFile image,
    required String plantId,
    String? speciesKey,
    String? speciesDisplayName,
  }) async {
    final photoUrl = await _plantPhotoFlowService.saveConditionCheckPhoto(
      image: image,
      plantId: plantId,
    );

    final analysisResult = await _conditionAnalysisService.analyzeCondition(
      PlantConditionAnalysisRequest(
        plantId: plantId,
        photoUrl: photoUrl,
        speciesKey: speciesKey,
        speciesDisplayName: speciesDisplayName,
      ),
    );

    await _plantService.insertPlantMemoryBestEffort(
      plantId: plantId,
      memoryType: PlantMemoryTypes.conditionCheck,
      eventType: analysisResult.conditionEventType,
      message: analysisResult.conditionMessage,
      photoUrl: photoUrl,
      isMock: analysisResult.isMock,
    );

    return PlantConditionCheckFlowResult(
      photoUrl: photoUrl,
      analysisResult: analysisResult,
    );
  }
}
