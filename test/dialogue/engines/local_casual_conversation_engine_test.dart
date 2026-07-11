import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/engines/local_casual_conversation_engine.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  test('uses a daily keyword in a short Korean reply without API', () {
    final engine = LocalCasualConversationEngine();
    final response = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '오늘 어때?',
        dailyKeywordContext: DailyKeywordContext(
          date: DateTime.utc(2026, 7, 8),
          locale: 'ko',
          keywords: const [
            DailyKeywordEntry(
              type: 'weather',
              keyword: '장맛비',
              hint: '비가 이어지는 날',
            ),
          ],
        ),
      ),
    );

    expect(response.route, ConversationRoute.localCasual);
    expect(response.usedDailyKeyword, isTrue);
    expect(response.usedApi, isFalse);
    expect(response.replyText, contains('장맛비'));
    expect(response.replyText, contains('무가리'));
  });

  test(
    'uses the plain local reply for null or empty daily keyword context',
    () {
      final engine = LocalCasualConversationEngine();
      final nullContextResponse = engine.generate(
        const ConversationRequest(
          plantId: 'plant-1',
          plantName: '무가리',
          userMessage: '안녕',
        ),
      );
      final emptyContextResponse = engine.generate(
        ConversationRequest(
          plantId: 'plant-1',
          plantName: '무가리',
          userMessage: '안녕',
          dailyKeywordContext: DailyKeywordContext(
            date: DateTime.utc(2026, 1, 1),
            locale: 'ko-KR',
            keywords: const [],
          ),
        ),
      );

      expect(nullContextResponse.usedDailyKeyword, isFalse);
      expect(emptyContextResponse.usedDailyKeyword, isFalse);
      expect(nullContextResponse.replyText, emptyContextResponse.replyText);
    },
  );
}
