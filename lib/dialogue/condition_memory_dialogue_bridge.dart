import '../models/latest_condition_memory.dart';
import '../services/plant_condition_analysis_service.dart';
import 'dialogue_engine.dart';

class ConditionDialogueDecision {
  const ConditionDialogueDecision({
    required this.situationKey,
    required this.conditionKey,
    required this.sourceLabel,
  });

  final String situationKey;
  final String conditionKey;
  final String sourceLabel;
}

class ConditionMemoryDialogueBridge {
  const ConditionMemoryDialogueBridge._();

  static const conditionKeyGeneral = 'general';
  static const conditionKeyHealthWatch = 'health_watch';
  static const conditionKeyWaterNeeded = 'water_needed';

  static ConditionDialogueDecision? decide(LatestConditionMemory? memory) {
    if (memory == null) {
      return null;
    }

    final eventType = PlantConditionEventTypes.normalize(memory.eventType);
    final message = memory.message?.toLowerCase().trim() ?? '';

    if ((eventType == null || eventType.isEmpty) && message.isEmpty) {
      return null;
    }

    if (_isWaterMemory(eventType: eventType, message: message)) {
      return const ConditionDialogueDecision(
        situationKey: PhotoConditionDialogueSituations.conditionWaterQuestion,
        conditionKey: conditionKeyWaterNeeded,
        sourceLabel: 'condition_memory_water',
      );
    }

    if (_isHealthWatchMemory(eventType: eventType, message: message)) {
      return const ConditionDialogueDecision(
        situationKey: PhotoConditionDialogueSituations.conditionCheckFollowup,
        conditionKey: conditionKeyHealthWatch,
        sourceLabel: 'condition_memory_health_watch',
      );
    }

    return const ConditionDialogueDecision(
      situationKey: PhotoConditionDialogueSituations.conditionCheckFollowup,
      conditionKey: conditionKeyGeneral,
      sourceLabel: 'condition_memory_general',
    );
  }

  static String? conditionKeyForDetectedSituation({
    required String detectedSituation,
    required LatestConditionMemory? memory,
  }) {
    final normalizedSituation = detectedSituation.trim();
    if (normalizedSituation.isEmpty) {
      return null;
    }

    final decision = decide(memory);
    if (normalizedSituation == 'thirsty' &&
        decision?.conditionKey == conditionKeyWaterNeeded) {
      return conditionKeyWaterNeeded;
    }

    return null;
  }

  static bool _isWaterMemory({
    required String? eventType,
    required String message,
  }) {
    return eventType == PlantConditionEventTypes.needsWater ||
        eventType == conditionKeyWaterNeeded ||
        _containsAny(message, const ['water_needed', 'thirsty', 'dry']);
  }

  static bool _isHealthWatchMemory({
    required String? eventType,
    required String message,
  }) {
    return eventType == PlantConditionEventTypes.lowLight ||
        eventType == PlantConditionEventTypes.pestRisk ||
        eventType == PlantConditionEventTypes.leafDamage ||
        eventType == conditionKeyHealthWatch ||
        _containsAny(message, const ['health_watch', 'wilting', 'weak']);
  }

  static bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) {
        return true;
      }
    }
    return false;
  }
}
