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

class DeepHealthAssessmentUsageRecoveryException implements Exception {
  const DeepHealthAssessmentUsageRecoveryException({
    required this.originalError,
    required this.releaseError,
  });

  final Object originalError;
  final Object releaseError;

  @override
  String toString() {
    return 'Deep health assessment failed and its usage reservation '
        'could not be released.';
  }
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
    final authorization = await _gateService.authorizeAndReserve(
      context: entitlementContext,
    );
    final reservationId = _validateAuthorization(authorization);
    final access = authorization.access;

    if (!access.allowed) {
      return DeepHealthAssessmentBlockedOutcome(access: access);
    }

    try {
      final photoUrl = await _savePhoto(image: image, plantId: plantId);
      final analysisResult = await _analyze(
        PlantConditionAnalysisRequest(
          plantId: plantId,
          photoUrl: photoUrl,
          speciesKey: speciesKey,
          speciesDisplayName: speciesDisplayName,
          deepHealthReservationId: reservationId,
        ),
      );
      _validatePaidAnalysis(analysisResult);

      final memoryPayload = _memoryBridge.fromNormalizedEvent(
        event: analysisResult.normalizedEvent,
        plantId: plantId,
        photoUrl: photoUrl,
      );
      await _insertMemory(memoryPayload);
      await _gateService.commitReservation(reservationId: reservationId!);

      return DeepHealthAssessmentCompletedOutcome(
        access: access,
        photoUrl: photoUrl,
        analysisResult: analysisResult,
        memoryPayload: memoryPayload,
      );
    } catch (error, stackTrace) {
      try {
        await _gateService.releaseReservation(
          reservationId: reservationId!,
        );
      } catch (releaseError) {
        throw DeepHealthAssessmentUsageRecoveryException(
          originalError: error,
          releaseError: releaseError,
        );
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  String? _validateAuthorization(
    DeepHealthAssessmentAuthorization authorization,
  ) {
    final access = authorization.access;
    final normalizedReservationId = authorization.reservationId?.trim();

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

    if (access.allowed &&
        (normalizedReservationId == null ||
            normalizedReservationId.isEmpty)) {
      throw StateError(
        'Allowed deep health assessment requires a usage reservation.',
      );
    }

    if (!access.allowed && normalizedReservationId != null) {
      throw StateError(
        'Blocked deep health assessment must not reserve usage.',
      );
    }

    return normalizedReservationId;
  }

  void _validatePaidAnalysis(PlantConditionAnalysisResult result) {
    if (result.isMock || result.normalizedEvent.isMock) {
      throw StateError(
        'Paid deep health assessment must not complete with mock data.',
      );
    }
  }
}
