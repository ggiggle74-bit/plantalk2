import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/gemini_default_state_observation_parser.dart';
import 'package:plantalk2/plant_analysis/adapters/kindwise_plant_health_response_parser.dart';
import 'package:plantalk2/plant_analysis/factories/existing_plant_state_check_service_factory.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';

void main() {
  test(
    'generalObservationService uses default_observation and does not call Kindwise',
    () async {
      var geminiCalls = 0;
      var kindwiseCalls = 0;
      final services = ExistingPlantStateCheckServiceFactory.withProxyCallbacks(
        invokeGeneralObservationProxy: ({required imageUrl}) async {
          geminiCalls += 1;
          return _geminiStablePayload();
        },
        invokeDeepHealthAssessmentProxy: ({required imageUrl}) async {
          kindwiseCalls += 1;
          return _kindwiseHealthyPayload();
        },
        onGeneralObservationFailure: _ignoreFailure,
        onDeepHealthAssessmentFailure: _ignoreFailure,
      ).build();

      final result = await services.generalObservationService.analyzeCondition(
        _request(),
      );

      expect(geminiCalls, 1);
      expect(kindwiseCalls, 0);
      expect(
        result.normalizedEvent.sourceProvider,
        GeminiDefaultStateObservationParser.providerKey,
      );
      expect(result.normalizedEvent.metadata, {
        'analysisType': PlantAnalysisTypes.defaultObservation,
      });
      expect(result.isMock, isFalse);
    },
  );

  test(
    'generalObservationService falls back to mock without calling Kindwise',
    () async {
      final backendError = StateError('gemini failed');
      final loggedErrors = <Object>[];
      var geminiCalls = 0;
      var kindwiseCalls = 0;
      final services = ExistingPlantStateCheckServiceFactory.withProxyCallbacks(
        invokeGeneralObservationProxy: ({required imageUrl}) async {
          geminiCalls += 1;
          throw backendError;
        },
        invokeDeepHealthAssessmentProxy: ({required imageUrl}) async {
          kindwiseCalls += 1;
          return _kindwiseHealthyPayload();
        },
        onGeneralObservationFailure: (error, stackTrace) {
          loggedErrors.add(error);
          loggedErrors.add(stackTrace);
        },
        onDeepHealthAssessmentFailure: _ignoreFailure,
      ).build();

      final result = await services.generalObservationService.analyzeCondition(
        _request(),
      );

      expect(geminiCalls, 1);
      expect(kindwiseCalls, 0);
      expect(loggedErrors.first, same(backendError));
      expect(loggedErrors.last, isA<StackTrace>());
      expect(result.isMock, isTrue);
      expect(result.normalizedEvent.isMock, isTrue);
      expect(result.normalizedEvent.metadata, {
        'analysisType': PlantAnalysisTypes.conditionCheck,
      });
    },
  );

  test(
    'deepHealthAssessmentService uses condition_check and does not call Gemini',
    () async {
      var geminiCalls = 0;
      var kindwiseCalls = 0;
      final services = ExistingPlantStateCheckServiceFactory.withProxyCallbacks(
        invokeGeneralObservationProxy: ({required imageUrl}) async {
          geminiCalls += 1;
          return _geminiStablePayload();
        },
        invokeDeepHealthAssessmentProxy: ({required imageUrl}) async {
          kindwiseCalls += 1;
          return _kindwiseHealthyPayload();
        },
        onGeneralObservationFailure: _ignoreFailure,
        onDeepHealthAssessmentFailure: _ignoreFailure,
      ).build();

      final result = await services.deepHealthAssessmentService
          .analyzeCondition(_request());

      expect(geminiCalls, 0);
      expect(kindwiseCalls, 1);
      expect(
        result.normalizedEvent.sourceProvider,
        KindwisePlantHealthResponseParser.providerKey,
      );
      expect(result.normalizedEvent.metadata, {
        'analysisType': PlantAnalysisTypes.conditionCheck,
      });
      expect(result.isMock, isFalse);
    },
  );

  test(
    'deepHealthAssessmentService falls back to mock without calling Gemini',
    () async {
      final backendError = StateError('kindwise failed');
      final loggedErrors = <Object>[];
      var geminiCalls = 0;
      var kindwiseCalls = 0;
      final services = ExistingPlantStateCheckServiceFactory.withProxyCallbacks(
        invokeGeneralObservationProxy: ({required imageUrl}) async {
          geminiCalls += 1;
          return _geminiStablePayload();
        },
        invokeDeepHealthAssessmentProxy: ({required imageUrl}) async {
          kindwiseCalls += 1;
          throw backendError;
        },
        onGeneralObservationFailure: _ignoreFailure,
        onDeepHealthAssessmentFailure: (error, stackTrace) {
          loggedErrors.add(error);
          loggedErrors.add(stackTrace);
        },
      ).build();

      final result = await services.deepHealthAssessmentService
          .analyzeCondition(_request());

      expect(geminiCalls, 0);
      expect(kindwiseCalls, 1);
      expect(loggedErrors.first, same(backendError));
      expect(loggedErrors.last, isA<StackTrace>());
      expect(result.isMock, isTrue);
      expect(result.normalizedEvent.isMock, isTrue);
    },
  );
}

PlantConditionAnalysisRequest _request() {
  return const PlantConditionAnalysisRequest(
    plantId: 'plant-1',
    photoUrl: 'https://example.test/condition-photo.jpg',
    speciesKey: 'pothos',
    speciesDisplayName: '스킨답서스',
  );
}

Map<String, dynamic> _geminiStablePayload() {
  return {
    'observation_id': 'observation-1',
    'observed_at': '2026-06-24T01:02:03Z',
    'image_quality': 'usable',
    'observation_state': 'stable_appearance',
    'evidence_tags': ['stable_foliage'],
  };
}

Map<String, dynamic> _kindwiseHealthyPayload() {
  return {
    'access_token': 'fake-kindwise-token',
    'created': 1782057600,
    'status': 'COMPLETED',
    'result': {
      'is_healthy': {'binary': true, 'probability': 0.94, 'threshold': 0.63},
      'disease': {'suggestions': const []},
    },
  };
}

void _ignoreFailure(Object error, StackTrace stackTrace) {}
