import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';
import 'package:plantalk2/dialogue/models/user_region_context.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  test(
    'carries plant, message, daily keyword, region, and condition memory',
    () {
      final keywordContext = DailyKeywordContext(
        date: DateTime.utc(2026, 7, 8),
        locale: 'ko',
        keywords: const [
          DailyKeywordEntry(type: 'weather', keyword: '장맛비', hint: '비가 이어지는 날'),
        ],
      );
      const regionContext = UserRegionContext(
        countryCode: 'KR',
        regionLabel: '제주',
        localityLabel: '제주시',
        precision: 'city',
        source: 'user_selected',
      );
      const memory = LatestConditionMemory(
        message: '사진을 보니 물이 조금 필요해 보여요.',
        eventType: 'needs_water',
      );

      final request = ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '오늘 어때?',
        dailyKeywordContext: keywordContext,
        userRegionContext: regionContext,
        latestConditionMemory: memory,
      );

      expect(request.plantId, 'plant-1');
      expect(request.plantName, '무가리');
      expect(request.userMessage, '오늘 어때?');
      expect(request.dailyKeywordContext, same(keywordContext));
      expect(request.userRegionContext, same(regionContext));
      expect(request.latestConditionMemory, same(memory));
    },
  );
}
