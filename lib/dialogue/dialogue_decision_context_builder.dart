import '../models/latest_condition_memory.dart';
import 'condition_memory_dialogue_bridge.dart';
import 'dialogue_engine.dart';

class DialogueDecisionContext {
  const DialogueDecisionContext({
    required this.input,
    required this.waterDay,
    required this.situationKey,
    required this.conditionKey,
    required this.conditionSource,
    required this.hasDetectedSituation,
    required this.usesConditionMemoryFallback,
  });

  final String input;
  final int waterDay;
  final String? situationKey;
  final String? conditionKey;
  final String? conditionSource;
  final bool hasDetectedSituation;
  final bool usesConditionMemoryFallback;
}

class DialogueDecisionContextBuilder {
  const DialogueDecisionContextBuilder();

  DialogueDecisionContext build({
    required String input,
    required int waterDay,
    LatestConditionMemory? conditionMemoryContext,
    String? previousUserMessage,
    int conditionMemoryReplyCount = 0,
    bool allowConditionMemoryFallback = true,
  }) {
    final detectedSituation = DialogueEngine.detectSituation(
      userMessage: input,
      waterDay: waterDay,
      previousUserMessage: previousUserMessage,
    );
    final hasDetectedSituation =
        detectedSituation != null && detectedSituation.trim().isNotEmpty;

    final conditionContext = allowConditionMemoryFallback
        ? DialogueEngine.photoConditionDialogueContext(
            userMessage: input,
            memoryMessage: conditionMemoryContext?.message,
            memoryEventType: conditionMemoryContext?.eventType,
            replyCount: conditionMemoryReplyCount,
          )
        : null;

    final conditionDecision = ConditionMemoryDialogueBridge.decide(
      conditionMemoryContext,
    );
    final detectedConditionKey = hasDetectedSituation
        ? ConditionMemoryDialogueBridge.conditionKeyForDetectedSituation(
            detectedSituation: detectedSituation,
            memory: conditionMemoryContext,
          )
        : null;
    final fallbackConditionDecision = conditionContext == null
        ? null
        : conditionDecision;

    return DialogueDecisionContext(
      input: input,
      waterDay: waterDay,
      situationKey:
          detectedSituation ??
          fallbackConditionDecision?.situationKey ??
          conditionContext?.situation,
      conditionKey: hasDetectedSituation
          ? detectedConditionKey
          : fallbackConditionDecision?.conditionKey,
      conditionSource: hasDetectedSituation
          ? null
          : fallbackConditionDecision?.sourceLabel,
      hasDetectedSituation: hasDetectedSituation,
      usesConditionMemoryFallback:
          !hasDetectedSituation && fallbackConditionDecision != null,
    );
  }
}
