import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_conversation_material_context.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_usage_ledger.dart';
import 'package:plantalk2/dialogue/models/user_region_context.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  test(
    'carries plant, message, daily material, usage, region, and memory',
    () {
      final materialContext = DailyConversationMaterialContext(
        date: DateTime.utc(2026, 7, 28),
        locale: 'ko-KR',
        materials: [
          DailyConversationMaterial(
            type: 'weather',
            keyword: '장맛비',
            hint: '비가 이어지는 날',
            plantHint: '실내 공기 흐름을 살펴보기',
            tone: 'gentle',
            fitScore: 0.82,
          ),
        ],
      );
      final usageLedger = ConversationUsageLedger();
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
        plantName: '초록이',
        userMessage: '오늘 어때?',
        mood: '밝음',
        friendship: 12,
        previousUserMessage: '어제 학교에서 속상했어.',
        previousPlantReply: '무슨 일이 있었는지 말해줘.',
        dailyConversationMaterialContext: materialContext,
        usageLedger: usageLedger,
        userRegionContext: regionContext,
        latestConditionMemory: memory,
      );

      expect(request.plantId, 'plant-1');
      expect(request.plantName, '초록이');
      expect(request.userMessage, '오늘 어때?');
      expect(request.mood, '밝음');
      expect(request.friendship, 12);
      expect(request.previousUserMessage, '어제 학교에서 속상했어.');
      expect(request.previousPlantReply, '무슨 일이 있었는지 말해줘.');
      expect(request.dailyConversationMaterialContext, same(materialContext));
      expect(request.usageLedger, same(usageLedger));
      expect(request.userRegionContext, same(regionContext));
      expect(request.latestConditionMemory, same(memory));
    },
  );
}
