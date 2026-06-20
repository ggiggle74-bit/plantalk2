import 'package:image_picker/image_picker.dart';

import '../plant_analysis/bridges/condition_check_memory_payload_bridge.dart';
import 'plant_condition_analysis_service.dart';
import 'plant_service.dart';
import 'plant_photo_flow_service.dart';

typedef SaveConditionCheckPhotoCallback =
    Future<String> Function({required XFile image, required String plantId});
typedef AnalyzeConditionCallback =
    Future<PlantConditionAnalysisResult> Function(
      PlantConditionAnalysisRequest request,
    );
typedef InsertConditionCheckMemoryCallback =
    Future<void> Function(ConditionCheckMemoryPayload payload);

class PlantConditionCheckFlowResult {
  const PlantConditionCheckFlowResult({
    required this.photoUrl,
    required this.analysisResult,
    required this.memoryPayload,
  });

  final String photoUrl;
  final PlantConditionAnalysisResult analysisResult;
  final ConditionCheckMemoryPayload memoryPayload;
}

class PlantConditionCheckFlowService {
  PlantConditionCheckFlowService({
    required PlantPhotoFlowService plantPhotoFlowService,
    required PlantConditionAnalysisService conditionAnalysisService,
    required PlantService plantService,
  }) : this.withCallbacks(
         saveConditionCheckPhoto: plantPhotoFlowService.saveConditionCheckPhoto,
         analyzeCondition: conditionAnalysisService.analyzeCondition,
         insertConditionCheckMemory: (payload) {
           return plantService.insertPlantMemoryBestEffort(
             plantId: payload.plantId,
             memoryType: payload.memoryType,
             eventType: payload.eventType,
             message: payload.message,
             photoUrl: payload.photoUrl,
             isMock: payload.isMock,
           );
         },
       );

  const PlantConditionCheckFlowService.withCallbacks({
    required SaveConditionCheckPhotoCallback saveConditionCheckPhoto,
    required AnalyzeConditionCallback analyzeCondition,
    required InsertConditionCheckMemoryCallback insertConditionCheckMemory,
  }) : _saveConditionCheckPhoto = saveConditionCheckPhoto,
       _analyzeCondition = analyzeCondition,
       _insertConditionCheckMemory = insertConditionCheckMemory;

  final SaveConditionCheckPhotoCallback _saveConditionCheckPhoto;
  final AnalyzeConditionCallback _analyzeCondition;
  final InsertConditionCheckMemoryCallback _insertConditionCheckMemory;

  Future<PlantConditionCheckFlowResult> checkCondition({
    required XFile image,
    required String plantId,
    String? speciesKey,
    String? speciesDisplayName,
  }) async {
    final photoUrl = await _saveConditionCheckPhoto(
      image: image,
      plantId: plantId,
    );

    final analysisResult = await _analyzeCondition(
      PlantConditionAnalysisRequest(
        plantId: plantId,
        photoUrl: photoUrl,
        speciesKey: speciesKey,
        speciesDisplayName: speciesDisplayName,
      ),
    );
    final memoryPayload = const ConditionCheckMemoryPayloadBridge()
        .fromNormalizedEvent(
          event: analysisResult.normalizedEvent,
          plantId: plantId,
          photoUrl: photoUrl,
        );

    await _insertConditionCheckMemory(memoryPayload);

    return PlantConditionCheckFlowResult(
      photoUrl: photoUrl,
      analysisResult: analysisResult,
      memoryPayload: memoryPayload,
    );
  }
}
