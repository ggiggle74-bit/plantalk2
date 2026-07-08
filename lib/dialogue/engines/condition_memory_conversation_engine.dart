import '../models/conversation_request.dart';
import '../models/conversation_response.dart';
import '../models/conversation_route.dart';

class ConditionMemoryConversationEngine {
  const ConditionMemoryConversationEngine();

  ConversationResponse? generate(ConversationRequest request) {
    final memory = request.latestConditionMemory;
    final message = memory?.message?.trim();
    final eventType = memory?.eventType?.trim();

    if (memory == null ||
        ((message == null || message.isEmpty) &&
            (eventType == null || eventType.isEmpty))) {
      return null;
    }

    return ConversationResponse(
      replyText: _replyFor(
        plantName: request.plantName,
        memoryMessage: message,
        eventType: eventType,
      ),
      route: ConversationRoute.conditionMemory,
      usedConditionMemory: true,
      debugReason: 'condition_memory',
    );
  }

  String _replyFor({
    required String plantName,
    required String? memoryMessage,
    required String? eventType,
  }) {
    final memory = memoryMessage;
    final normalizedEventType = eventType?.toLowerCase();

    if (normalizedEventType == 'needs_water' ||
        normalizedEventType == 'water_needed') {
      return '최근 상태 확인에서는 물이 조금 신경 쓰였어. 바로 단정하진 말고 흙이 말랐는지 먼저 봐줘.';
    }

    if (normalizedEventType == 'normal') {
      return '최근 확인으로는 큰 이상 신호는 적었어. 그래도 잎 색이랑 흙 상태는 한 번 더 봐줘.';
    }

    if (normalizedEventType == 'uncertain') {
      final suffix = memory == null || memory.isEmpty ? '' : ' $memory';
      return '최근 사진만으로는 확실히 말하기 어려웠어.$suffix 필요하면 사진을 다시 같이 보자.';
    }

    if (memory != null && memory.isNotEmpty) {
      return '최근 상태 확인에서는 이렇게 기억하고 있어. $memory 단정하진 말고 흙이나 잎을 한 번 더 확인해줘.';
    }

    final plantLabel = plantName.trim().isEmpty ? '이 식물' : plantName.trim();
    return '$plantLabel 상태는 최근 확인 기록만 기준으로 조심해서 봐야 해. 사진이나 흙 상태를 다시 확인해줘.';
  }
}
