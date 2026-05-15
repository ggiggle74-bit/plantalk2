import 'package:image_picker/image_picker.dart';

import 'plant_condition_analysis_service.dart';
import 'plant_photo_flow_service.dart';

class PlantConditionCheckFlowService {
  PlantConditionCheckFlowService({
    required PlantPhotoFlowService plantPhotoFlowService,
    required PlantConditionAnalysisService conditionAnalysisService,
    ImagePicker? imagePicker,
  }) : _plantPhotoFlowService = plantPhotoFlowService,
       _conditionAnalysisService = conditionAnalysisService,
       _imagePicker = imagePicker ?? ImagePicker();

  final PlantPhotoFlowService _plantPhotoFlowService;
  final PlantConditionAnalysisService _conditionAnalysisService;
  final ImagePicker _imagePicker;

  Future<PlantConditionAnalysisResult?> checkCondition({
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

    return _conditionAnalysisService.analyzeCondition(
      PlantConditionAnalysisRequest(
        plantId: plantId,
        photoUrl: photoUrl,
        speciesKey: speciesKey,
        speciesDisplayName: speciesDisplayName,
      ),
    );
  }
}
