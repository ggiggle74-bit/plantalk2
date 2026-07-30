import 'package:image_picker/image_picker.dart';

import '../monetization/models/entitlement_check_context.dart';
import '../monetization/models/entitlement_check_result.dart';
import '../monetization/models/paid_feature.dart';
import '../plant_analysis/bridges/condition_check_memory_payload_bridge.dart';
import '../plant_analysis/bridges/deep_health_assessment_memory_payload_bridge.dart';
import 'deep_health_assessment_gate_service.dart';
import 'plant_condition_analysis_service.dart';

typedef SaveDeepHealthAssessmentPhotoCallback =
    Future<String> Function({required XFile image, required String plantId});
typedef AnalyzeDeepHealthAssessmentCallback =
    Future<PlantConditionAnalysisResult> Function(
      PlantConditionAnalysisRequest request,
    );
typedef InsertDeepHealthAssessmentMemoryCallback =
    Future<void> Function(ConditionCheckMemoryPayload payload);

abstract class DeepHealthAssessmentFlowOutcome {
  const DeepHealthAssessmentFlowOutcome({required this.access});

  final EntitlementCheckResult access;

  bool get isCompleted;
}

class DeepHealthAssessmentBlockedOutcome
    extends DeepHealthAssessmentFlowOutcome {
  const DeepHealthAssessmentBlockedOutcome({required super.access});

  @override
  bool get isCompleted => false;
}

class DeepHealthAssessmentCompletedOutcome
    extends DeepHealthAssessmentFlowOutcome {
  const DeepHealthAssessmentCompletedOutcome({
    required super.access,
    required this.photoUrl,
    required this.analysisResult,
    required this.memoryPayload,
  });

  final String photoUrl;
  final PlantConditionAnalysisResult analysisResult;
  final ConditionCheckMemoryPayload memoryPayload;

  @override
  bool get isCompleted => true;
}

class DeepHealthAssessmentFlowService {
  const DeepHealthAssessmentFlowService({
    required DeepHealthAssessmentGateService gateService,
    required SaveDeepHealthAssessmentPhotoCallback savePhoto,
    required AnalyzeDeepHealthAssessmentCallback analyze,
    required InsertDeepHealthAssessmentMemoryCallback insertMemory,
    DeepHealthAssessmentMemoryPayloadBridge memoryBridge =
        const DeepHealthAssessmentMemoryPayloadBridge(),
  }) : _gateService = gateService,
       _savePhoto = savePhoto,
       _analyze = analyze,
       _insertMemory = insertMemory,
       _memoryBridge = memoryBridge;

  final DeepHealthAssessmentGateService _gateService;
  final SaveDeepHealthAssessmentPhotoCallback _savePhoto;
  final AnalyzeDeepHealthAssessmentCallback _analyze;
  final InsertDeepHealthAssessmentMemoryCallback _insertMemory;
  final DeepHealthAssessmentMemoryPayloadBridge _memoryBridge;

  Future<DeepHealthAssessmentFlowOutcome> assess({
    required XFile image,
    required String plantId,
    String? speciesKey,
    String? speciesDisplayName,
    EntitlementCheckContext entitlementContext =
        const EntitlementCheckContext(),
  }) async {
    final access = await _gateService.authorizeAndReserve(
      context: entitlementContext,
    );
    _validateAccess(access);

    if (!access.allowed) {
      return DeepHealthAssessmentBlockedOutcome(access: access);
    }

    final photoUrl = await _savePhoto(image: image, plantId: plantId);
    final analysisResult = await _analyze(
      PlantConditionAnalysisRequest(
        plantId: plantId,
        photoUrl: photoUrl,
        speciesKey: speciesKey,
        speciesDisplayName: speciesDisplayName,
      ),
    );
    final memoryPayload = _memoryBridge.fromNormalizedEvent(
      event: analysisResult.normalizedEvent,
      plantId: plantId,
      photoUrl: photoUrl,
    );

    await _insertMemory(memoryPayload);

    return DeepHealthAssessmentCompletedOutcome(
      access: access,
      photoUrl: photoUrl,
      analysisResult: analysisResult,
      memoryPayload: memoryPayload,
    );
  }

  void _validateAccess(EntitlementCheckResult access) {
    if (access.feature != PaidFeature.deepHealthAssessment) {
      throw StateError(
        'Deep health assessment gate returned a result for another feature.',
      );
    }

    if (access.allowed == access.requiresPayment) {
      throw StateError(
        'Deep health assessment gate returned an inconsistent decision.',
      );
    }
  }
}
