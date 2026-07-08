import '../models/conversation_request.dart';
import '../models/conversation_response.dart';
import '../models/conversation_route.dart';
import '../models/daily_keyword_context.dart';
import '../tone/mugari_tone_composer.dart';

class LocalCasualConversationEngine {
  const LocalCasualConversationEngine({
    this.toneComposer = const MugariToneComposer(),
  });

  final MugariToneComposer toneComposer;

  ConversationResponse generate(ConversationRequest request) {
    final keyword = _keywordFor(request);
    final plantName = _plantLabel(request.plantName);
    final base = keyword == null
        ? _plainCasualReply(request.userMessage, plantName)
        : '오늘은 ${keyword.keyword} 얘기가 있네. $plantName도 천천히 하루를 시작해볼까?';

    return ConversationResponse(
      replyText: toneComposer.apply(
        base,
        plantName: request.plantName,
        mood: request.mood,
      ),
      route: ConversationRoute.localCasual,
      usedDailyKeyword: keyword != null,
      debugReason: keyword == null ? 'local_casual' : 'local_casual_keyword',
    );
  }

  DailyKeywordEntry? _keywordFor(ConversationRequest request) {
    final context = request.dailyKeywordContext;
    if (context == null || !context.hasKeywords) {
      return null;
    }

    final message = request.userMessage.trim();
    if (!_shouldUseDailyKeyword(message)) {
      return null;
    }

    return context.pickForSeed(
      request.plantId.hashCode ^ request.userMessage.hashCode,
    );
  }

  bool _shouldUseDailyKeyword(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('오늘') ||
        normalized.contains('안녕') ||
        normalized.contains('hello') ||
        normalized.contains('hi');
  }

  String _plainCasualReply(String userMessage, String plantName) {
    final normalized = userMessage.toLowerCase().trim();
    if (normalized.contains('심심') || normalized.contains('외로')) {
      return '나 여기 있어. $plantName도 네가 와서 조금 덜 심심해졌어.';
    }

    if (normalized.contains('뭐해') || normalized.contains('뭐 해')) {
      return '$plantName은 잎 정리하면서 네 말 기다리고 있었어.';
    }

    if (normalized.contains('기분')) {
      return '$plantName은 오늘 꽤 잔잔해. 네가 와서 더 괜찮아졌어.';
    }

    return '왔구나. $plantName도 조용히 너 기다리고 있었어.';
  }

  String _plantLabel(String plantName) {
    final trimmed = plantName.trim();
    return trimmed.isEmpty ? '이 식물' : trimmed;
  }
}
