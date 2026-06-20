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

  test('preserves non-empty provider message after trimming', () async {
    final result = await _analyzeSingleEvent(
      eventType: PlantAnalysisEventTypes.waterNeeded,
      note: '  제공자가 판단한 물 부족 신호예요.  ',
    );

    expect(result.conditionEventType, PlantConditionEventTypes.needsWater);
    expect(result.conditionMessage, '제공자가 판단한 물 부족 신호예요.');
    expect(result.normalizedEvent.message, result.conditionMessage);
  });

  test('uses water-specific fallback for water_needed', () async {
    final result = await _analyzeSingleEvent(
      eventType: PlantAnalysisEventTypes.waterNeeded,
    );

    expect(result.conditionEventType, PlantConditionEventTypes.needsWater);
    expect(result.conditionMessage, '사진을 보니 물이 조금 필요해 보여요.');
    expect(result.normalizedEvent.message, result.conditionMessage);
    expect(result.conditionMessage, isNot(contains('큰 이상이 없어 보여요')));
  });

  test('uses low-light fallback for light_needed', () async {
    final result = await _analyzeSingleEvent(
      eventType: PlantAnalysisEventTypes.lightNeeded,
    );

    expect(result.conditionEventType, PlantConditionEventTypes.lowLight);
    expect(result.conditionMessage, '사진을 보니 빛이 조금 부족해 보여요.');
    expect(result.normalizedEvent.message, result.conditionMessage);
  });

  test('maps pest and disease events to pest risk fallback', () async {
    for (final eventType in const [
      PlantAnalysisEventTypes.pestSuspected,
      PlantAnalysisEventTypes.diseaseSuspected,
    ]) {
      final result = await _analyzeSingleEvent(eventType: eventType);

      expect(result.conditionEventType, PlantConditionEventTypes.pestRisk);
      expect(result.conditionMessage, '사진을 보니 잎 상태를 조금 더 살펴보는 게 좋겠어요.');
      expect(result.normalizedEvent.message, result.conditionMessage);
    }
  });

  test('maps leaf-damage events without healthy fallback', () async {
    for (final eventType in const [
      PlantAnalysisEventTypes.overwaterSuspected,
      PlantAnalysisEventTypes.tooMuchSunSuspected,
      PlantAnalysisEventTypes.repottingSuggested,
      PlantAnalysisEventTypes.soilCheckNeeded,
      PlantAnalysisEventTypes.temperatureStressSuspected,
      PlantAnalysisEventTypes.humidityIssueSuspected,
    ]) {
      final result = await _analyzeSingleEvent(eventType: eventType);

      expect(result.conditionEventType, PlantConditionEventTypes.leafDamage);
      expect(result.normalizedEvent.message, result.conditionMessage);
      expect(result.conditionMessage, isNot(contains('큰 이상이 없어 보여요')));
      expect(result.conditionMessage.trim(), isNotEmpty);
    }
  });

  test('keeps health_ok healthy fallback and normal type', () async {
    final result = await _analyzeSingleEvent(
      eventType: PlantAnalysisEventTypes.healthOk,
    );

    expect(result.conditionEventType, PlantConditionEventTypes.normal);
    expect(result.conditionMessage, '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.');
    expect(result.normalizedEvent.message, result.conditionMessage);
  });

  test('maps growth events to normal with growth fallback', () async {
    for (final eventType in const [
      PlantAnalysisEventTypes.growthPositive,
      PlantAnalysisEventTypes.newLeafObserved,
      PlantAnalysisEventTypes.floweringObserved,
    ]) {
      final result = await _analyzeSingleEvent(eventType: eventType);

      expect(result.conditionEventType, PlantConditionEventTypes.normal);
      expect(result.conditionMessage, '사진을 보니 새 성장 신호가 보여요. 상태는 계속 관찰해 주세요.');
      expect(result.normalizedEvent.message, result.conditionMessage);
      expect(result.conditionMessage, isNot(contains('큰 이상이 없어 보여요')));
    }
  });

  test(
    'keeps condition_uncertain cautious fallback and uncertain type',
    () async {
      final result = await _analyzeSingleEvent(
        eventType: PlantAnalysisEventTypes.conditionUncertain,
      );

      expect(result.conditionEventType, PlantConditionEventTypes.uncertain);
      expect(result.conditionMessage, '사진만으로는 상태를 확실히 판단하기 어려워요.');
      expect(result.normalizedEvent.message, result.conditionMessage);
      expect(result.conditionMessage, isNot(contains('큰 이상이 없어 보여요')));
    },
  );

  test('preserves confidence and normalized provider metadata', () async {
    final observedAt = DateTime.utc(2026, 6, 20, 7, 30);

    final result = await _analyzeSingleEvent(
      eventType: PlantAnalysisEventTypes.lightNeeded,
      confidence: 0.84,
      observedAt: observedAt,
      providerResultId: 'provider-result-42',
      isMock: false,
    );

    expect(result.normalizedEvent.confidence, 0.84);
    expect(result.normalizedEvent.sourceProvider, 'fake_provider');
    expect(result.normalizedEvent.observedAt, observedAt);
    expect(result.normalizedEvent.sourceResultId, 'provider-result-42');
    expect(result.normalizedEvent.isMock, isFalse);
    expect(result.isMock, isFalse);
    expect(result.normalizedEvent.metadata, {
      'analysisType': PlantAnalysisTypes.conditionCheck,
    });
  });

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

Future<PlantConditionAnalysisResult> _analyzeSingleEvent({
  required String eventType,
  String? note,
  double? confidence,
  DateTime? observedAt,
  String? providerResultId,
  bool isMock = true,
}) {
  final service = MockPlantConditionAnalysisService(
    plantAnalysisService: PlantAnalysisService(
      adapter: _FakePlantAnalysisAdapter(
        ExternalPlantAnalysisResult(
          providerKey: 'fake_provider',
          analysisType: PlantAnalysisTypes.conditionCheck,
          providerResultId: providerResultId,
          conditionEventHints: [
            ExternalPlantConditionEventHint(
              eventType: eventType,
              confidence: confidence,
              note: note,
            ),
          ],
          isMock: isMock,
          createdAt: observedAt,
        ),
      ),
    ),
  );

  return service.analyzeCondition(
    const PlantConditionAnalysisRequest(
      plantId: 'plant-1',
      photoUrl: 'https://example.test/photo.jpg',
    ),
  );
}
