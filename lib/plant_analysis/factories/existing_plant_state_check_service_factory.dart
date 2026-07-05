import 'package:flutter/foundation.dart';

import '../../services/plant_condition_analysis_service.dart';
import '../adapters/gemini_default_state_observation_adapter.dart';
import '../adapters/kindwise_plant_health_adapter.dart';
import '../models/plant_analysis_input.dart';
import '../services/plant_analysis_service.dart';
import 'gemini_default_observation_service_factory.dart';
import 'kindwise_plant_health_service_factory.dart';

class ExistingPlantStateCheckAnalysisServices {
  const ExistingPlantStateCheckAnalysisServices({
    required this.generalObservationService,
    required this.deepHealthAssessmentService,
  });

  final PlantConditionAnalysisService generalObservationService;
  final PlantConditionAnalysisService deepHealthAssessmentService;
}

class ExistingPlantStateCheckServiceFactory {
  const ExistingPlantStateCheckServiceFactory._({
    required PlantAnalysisService generalObservationPlantAnalysisService,
    required PlantAnalysisService deepHealthAssessmentPlantAnalysisService,
    required PlantConditionAnalysisFailureLogger onGeneralObservationFailure,
    required PlantConditionAnalysisFailureLogger onDeepHealthAssessmentFailure,
  }) : _generalObservationPlantAnalysisService =
           generalObservationPlantAnalysisService,
       _deepHealthAssessmentPlantAnalysisService =
           deepHealthAssessmentPlantAnalysisService,
       _onGeneralObservationFailure = onGeneralObservationFailure,
       _onDeepHealthAssessmentFailure = onDeepHealthAssessmentFailure;

  factory ExistingPlantStateCheckServiceFactory.supabase({
    PlantConditionAnalysisFailureLogger? onGeneralObservationFailure,
    PlantConditionAnalysisFailureLogger? onDeepHealthAssessmentFailure,
  }) {
    return ExistingPlantStateCheckServiceFactory._(
      generalObservationPlantAnalysisService:
          GeminiDefaultObservationServiceFactory.supabase().build(),
      deepHealthAssessmentPlantAnalysisService:
          KindwisePlantHealthServiceFactory.supabase().build(),
      onGeneralObservationFailure:
          onGeneralObservationFailure ?? _logGeneralObservationFailure,
      onDeepHealthAssessmentFailure:
          onDeepHealthAssessmentFailure ?? _logDeepHealthAssessmentFailure,
    );
  }

  factory ExistingPlantStateCheckServiceFactory.withProxyCallbacks({
    required InvokeGeminiDefaultObservationProxyCallback
    invokeGeneralObservationProxy,
    required InvokeKindwisePlantHealthProxyCallback
    invokeDeepHealthAssessmentProxy,
    PlantConditionAnalysisFailureLogger? onGeneralObservationFailure,
    PlantConditionAnalysisFailureLogger? onDeepHealthAssessmentFailure,
  }) {
    return ExistingPlantStateCheckServiceFactory._(
      generalObservationPlantAnalysisService:
          GeminiDefaultObservationServiceFactory.withProxyCallback(
            invokeProxy: invokeGeneralObservationProxy,
          ).build(),
      deepHealthAssessmentPlantAnalysisService:
          KindwisePlantHealthServiceFactory.withProxyCallback(
            invokeProxy: invokeDeepHealthAssessmentProxy,
          ).build(),
      onGeneralObservationFailure:
          onGeneralObservationFailure ?? _logGeneralObservationFailure,
      onDeepHealthAssessmentFailure:
          onDeepHealthAssessmentFailure ?? _logDeepHealthAssessmentFailure,
    );
  }

  final PlantAnalysisService _generalObservationPlantAnalysisService;
  final PlantAnalysisService _deepHealthAssessmentPlantAnalysisService;
  final PlantConditionAnalysisFailureLogger _onGeneralObservationFailure;
  final PlantConditionAnalysisFailureLogger _onDeepHealthAssessmentFailure;

  ExistingPlantStateCheckAnalysisServices build() {
    return ExistingPlantStateCheckAnalysisServices(
      generalObservationService: FallbackPlantConditionAnalysisService(
        primary: PlantAnalysisBackedConditionAnalysisService(
          plantAnalysisService: _generalObservationPlantAnalysisService,
          analysisType: PlantAnalysisTypes.defaultObservation,
        ),
        fallback: const MockPlantConditionAnalysisService(),
        onPrimaryFailure: _onGeneralObservationFailure,
      ),
      deepHealthAssessmentService: FallbackPlantConditionAnalysisService(
        primary: PlantAnalysisBackedConditionAnalysisService(
          plantAnalysisService: _deepHealthAssessmentPlantAnalysisService,
          analysisType: PlantAnalysisTypes.conditionCheck,
        ),
        fallback: const MockPlantConditionAnalysisService(),
        onPrimaryFailure: _onDeepHealthAssessmentFailure,
      ),
    );
  }
}

void _logGeneralObservationFailure(Object error, StackTrace stackTrace) {
  debugPrint(
    'Existing plant default_observation failed; using explicit mock fallback. '
    'Error: $error',
  );
  debugPrint('Existing plant default_observation stack trace: $stackTrace');
}

void _logDeepHealthAssessmentFailure(Object error, StackTrace stackTrace) {
  debugPrint(
    'Existing plant deep health assessment failed; using explicit mock fallback. '
    'Error: $error',
  );
  debugPrint('Existing plant deep health assessment stack trace: $stackTrace');
}
