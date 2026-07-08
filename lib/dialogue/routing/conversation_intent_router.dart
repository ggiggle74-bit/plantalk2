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

    return ConversationRoute.fallback;
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
    if (_directlyAddressesPlant(message, plantName)) {
      return true;
    }

    return _containsAny(message, const [
          '안녕',
          '하이',
          '반가워',
          '뭐해',
          '뭐 해',
          '오늘 어때',
          '요즘 어때',
          '심심',
          '무가리야',
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
      'repot',
      'fertilizer',
      'humidity',
      'sunlight',
      'pest',
    ]);
  }

  bool _directlyAddressesPlant(String message, String plantName) {
    final normalizedPlantName = plantName.toLowerCase().trim();
    if (normalizedPlantName.isEmpty) {
      return false;
    }

    final compactMessage = message.replaceAll(RegExp(r'\s+'), '');
    final compactName = normalizedPlantName.replaceAll(RegExp(r'\s+'), '');

    return compactMessage == compactName ||
        compactMessage.startsWith('$compactName아') ||
        compactMessage.startsWith('$compactName야');
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
