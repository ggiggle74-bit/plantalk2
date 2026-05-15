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
    ImagePicker? imagePicker,
  }) : _plantPhotoFlowService = plantPhotoFlowService,
       _conditionAnalysisService = conditionAnalysisService,
       _plantService = plantService,
       _imagePicker = imagePicker ?? ImagePicker();

  final PlantPhotoFlowService _plantPhotoFlowService;
  final PlantConditionAnalysisService _conditionAnalysisService;
  final PlantService _plantService;
  final ImagePicker _imagePicker;

  Future<PlantConditionCheckFlowResult?> checkCondition({
    required String plantId,
    String? speciesKey,
    String? speciesDisplayName,
  }) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

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
      memoryType: 'condition_check',
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
