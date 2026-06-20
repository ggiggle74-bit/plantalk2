import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/dialogue_decision_context_builder.dart';
import 'package:plantalk2/dialogue/dialogue_engine.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';
import 'package:plantalk2/plant_analysis/adapters/plant_analysis_adapter.dart';
import 'package:plantalk2/plant_analysis/bridges/condition_check_memory_payload_bridge.dart';
import 'package:plantalk2/plant_analysis/models/external_plant_analysis_result.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';
import 'package:plantalk2/plant_analysis/normalizers/plant_analysis_normalizer.dart';
import 'package:plantalk2/plant_analysis/services/plant_analysis_service.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';

void main() {
  test(
    'mock condition analysis uses cautious message for uncertainty',
    () async {
      final uncertainService = MockPlantConditionAnalysisService(
        plantAnalysisService: PlantAnalysisService(
          adapter: _FakePlantAnalysisAdapter(
            ExternalPlantAnalysisResult(
              providerKey: 'fake_provider',
              analysisType: PlantAnalysisTypes.conditionCheck,
              conditionEventHints: const [
                ExternalPlantConditionEventHint(
                  eventType: PlantAnalysisEventTypes.conditionUncertain,
                ),
              ],
              isMock: true,
            ),
          ),
        ),
      );

      final uncertainResult = await uncertainService.analyzeCondition(
        const PlantConditionAnalysisRequest(
          plantId: 'plant-1',
          photoUrl: 'https://example.test/photo.jpg',
        ),
      );

      expect(
        uncertainResult.conditionEventType,
        PlantConditionEventTypes.uncertain,
      );
      expect(uncertainResult.conditionMessage, '사진만으로는 상태를 확실히 판단하기 어려워요.');
      expect(
        uncertainResult.normalizedEvent.message,
        uncertainResult.conditionMessage,
      );
      expect(uncertainResult.conditionMessage, isNot(contains('큰 이상이 없어 보여요')));

      final healthyService = MockPlantConditionAnalysisService(
        plantAnalysisService: PlantAnalysisService(
          adapter: _FakePlantAnalysisAdapter(
            ExternalPlantAnalysisResult(
              providerKey: 'fake_provider',
              analysisType: PlantAnalysisTypes.conditionCheck,
              conditionEventHints: const [
                ExternalPlantConditionEventHint(
                  eventType: PlantAnalysisEventTypes.healthOk,
                ),
              ],
              isMock: true,
            ),
          ),
        ),
      );

      final healthyResult = await healthyService.analyzeCondition(
        const PlantConditionAnalysisRequest(
          plantId: 'plant-1',
          photoUrl: 'https://example.test/photo.jpg',
        ),
      );

      expect(healthyResult.conditionEventType, PlantConditionEventTypes.normal);
      expect(healthyResult.conditionMessage, '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.');
      expect(
        healthyResult.normalizedEvent.message,
        healthyResult.conditionMessage,
      );
    },
  );

  test(
    'condition uncertainty survives analysis, memory, and dialogue slots',
    () {
      const normalizer = PlantAnalysisNormalizer();
      const bridge = ConditionCheckMemoryPayloadBridge();
      const contextBuilder = DialogueDecisionContextBuilder();

      final externalResult = ExternalPlantAnalysisResult(
        providerKey: 'test_provider',
        analysisType: PlantAnalysisTypes.conditionCheck,
        providerResultId: 'provider-result-1',
        isMock: true,
        createdAt: DateTime.utc(2026, 6, 20),
      );

      final normalizedEvents = normalizer.normalize(externalResult);

      expect(normalizedEvents, hasLength(1));
      expect(
        normalizedEvents.single.eventType,
        PlantAnalysisEventTypes.conditionUncertain,
      );

      final payload = bridge.fromNormalizedEvent(
        event: normalizedEvents.single,
        plantId: 'plant-1',
        photoUrl: 'https://example.test/photo.jpg',
      );

      expect(payload.eventType, PlantConditionEventTypes.uncertain);
      expect(payload.eventType, isNot(PlantConditionEventTypes.normal));
      expect(payload.message, '사진만으로는 상태를 확실히 판단하기 어려워요.');

      final memory = LatestConditionMemory.fromRow({
        'message': payload.message,
        'event_type': payload.eventType,
      });

      expect(memory, isNotNull);
      expect(memory!.eventType, PlantConditionEventTypes.uncertain);
      expect(memory.message, payload.message);

      final decisionContext = contextBuilder.build(
        input: '상태 어때?',
        waterDay: 0,
        plantName: '초록이',
        conditionMemoryContext: memory,
      );

      expect(decisionContext.usesConditionMemoryFallback, isTrue);
      expect(
        decisionContext.situationKey,
        PhotoConditionDialogueSituations.conditionCheckFollowup,
      );
      expect(decisionContext.conditionKey, 'general');
      expect(decisionContext.conditionSource, 'condition_memory_general');
      expect(
        decisionContext.situationKey,
        isNot(PhotoConditionDialogueSituations.conditionCheckRequest),
      );

      final dialogueContext = DialogueEngine.photoConditionDialogueContext(
        userMessage: '상태 어때?',
        memoryMessage: memory.message,
        memoryEventType: memory.eventType,
        replyCount: 0,
      );

      expect(dialogueContext, isNotNull);
      expect(dialogueContext!.eventType, PlantConditionEventTypes.uncertain);

      final localReply = DialogueEngine.conditionMemoryReply(
        plantName: '초록이',
        waterDay: 0,
        context: dialogueContext,
      );

      expect(localReply, isNotNull);
      expect(localReply, contains(payload.message));
      expect(localReply, isNot(contains('normal')));
      expect(localReply, isNot(contains('큰 이상 없어 보였어')));
      expect(localReply, isNot(contains('큰 이상이 없어 보여요')));
    },
  );
}

class _FakePlantAnalysisAdapter implements PlantAnalysisAdapter {
  const _FakePlantAnalysisAdapter(this.result);

  final ExternalPlantAnalysisResult result;

  @override
  String get providerKey => 'fake_plant_analysis';

  @override
  Future<ExternalPlantAnalysisResult> analyze(PlantAnalysisInput input) async {
    return result;
  }
}
