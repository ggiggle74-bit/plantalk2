import '../models/conversation_request.dart';
import '../models/conversation_route.dart';

class ConversationIntentRouter {
  const ConversationIntentRouter();

  ConversationRoute route(ConversationRequest request) {
    final message = request.userMessage.toLowerCase().trim();
    if (message.isEmpty) {
      return ConversationRoute.fallback;
    }

    if (request.latestConditionMemory != null &&
        _isConditionFollowUp(message)) {
      return ConversationRoute.conditionMemory;
    }

    if (_isComplexOrKnowledgeLike(message)) {
      return ConversationRoute.api;
    }

    if (_isLocalCasual(message, request.plantName)) {
      return ConversationRoute.localCasual;
    }

    return ConversationRoute.api;
  }

  bool _isConditionFollowUp(String message) {
    return _containsAny(message, const [
      '괜찮아',
      '괜찮니',
      '물 줘',
      '물 줄까',
      '물 줘야',
      '물 필요',
      '왜 처졌',
      '처졌',
      '시들',
      '상태 어때',
      '상태가 어때',
      '상태 어땠',
      '상태가 어땠',
      '최근 상태',
      '상태',
      '건강',
      '아파',
      '사진 봤',
      '사진으로',
      'condition',
      'health',
      'status',
      'water',
    ]);
  }

  bool _isLocalCasual(String message, String plantName) {
    final addressedRemainder = _directAddressRemainder(message, plantName);
    if (addressedRemainder != null && addressedRemainder.isEmpty) {
      return true;
    }

    final casualMessage = addressedRemainder ?? message;
    return _containsAny(casualMessage, const [
          '안녕',
          '하이',
          '반가워',
          '뭐해',
          '뭐 해',
          '오늘 어때',
          '요즘 어때',
          '심심',
          '기분 어때',
          '기분은 어때',
          '잘 지내',
          '잘지내',
          '외로',
        ]) ||
        _containsAnyWord(message, const ['hi', 'hello', 'hey']);
  }

  bool _isComplexOrKnowledgeLike(String message) {
    if (message.length >= 42) {
      return true;
    }

    return _containsAny(message, const [
      '어떻게 키워',
      '어떻게 해야',
      '왜 그런',
      '왜 ',
      '왜?',
      '무슨 뜻',
      '알려줘',
      '알려 줘',
      '어떻게 만들어',
      '어떻게 작동',
      '원인',
      '방법',
      '분갈이',
      '가지치기',
      '병충해',
      '해충',
      '비료',
      '영양제',
      '햇빛',
      '광량',
      '온도',
      '습도',
      '흙 배합',
      '전문',
      '자세히',
      '설명',
      'care guide',
      'why ',
      'how ',
      'what is',
      'explain',
      'repot',
      'fertilizer',
      'humidity',
      'sunlight',
      'pest',
    ]);
  }

  String? _directAddressRemainder(String message, String plantName) {
    final normalizedPlantName = plantName.toLowerCase().trim();
    if (normalizedPlantName.isEmpty) {
      return null;
    }

    final prefixes = [
      '${normalizedPlantName}아',
      '${normalizedPlantName}야',
      normalizedPlantName,
    ];
    for (final prefix in prefixes) {
      if (message == prefix) {
        return '';
      }
      if (!message.startsWith(prefix)) {
        continue;
      }

      final nextIndex = prefix.length;
      if (message.length <= nextIndex) {
        return '';
      }
      final separator = message[nextIndex];
      if (!RegExp(r'[\s,.!?]').hasMatch(separator)) {
        continue;
      }

      return message
          .substring(nextIndex)
          .replaceFirst(RegExp(r'^[\s,.!?]+'), '')
          .trim();
    }

    return null;
  }

  bool _containsAny(String message, List<String> keywords) {
    for (final keyword in keywords) {
      if (message.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  bool _containsAnyWord(String message, List<String> words) {
    for (final word in words) {
      if (RegExp('(^|[^a-z])$word([^a-z]|\$)').hasMatch(message)) {
        return true;
      }
    }
    return false;
  }
}
