import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_conversation_material_context.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_opening_context.dart';
import 'package:plantalk2/dialogue/engines/local_casual_conversation_engine.dart';
import 'package:plantalk2/dialogue/models/conversation_request.dart';
import 'package:plantalk2/dialogue/models/conversation_route.dart';
import 'package:plantalk2/dialogue/models/conversation_usage_ledger.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  final now = DateTime.utc(2026, 7, 28);

  test('uses projected daily material in a local reply without API', () {
    const engine = LocalCasualConversationEngine();
    final ledger = ConversationUsageLedger();
    final response = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '오늘 뭐해?',
        now: now,
        dailyConversationMaterialContext: _materialContext(
          now,
          [
            DailyConversationMaterial(
              type: 'weather',
              keyword: '장맛비',
              hint: '비가 이어지는 날',
              plantHint: '실내 공기 흐름을 살펴보자',
              tone: 'gentle',
              fitScore: 0.82,
            ),
          ],
        ),
        usageLedger: ledger,
      ),
    );

    expect(response.route, ConversationRoute.localCasual);
    expect(response.usedDailyKeyword, isTrue);
    expect(response.usedApi, isFalse);
    expect(response.replyText, contains('장맛비'));
    expect(response.replyText, contains('무가리'));
    expect(ledger.trackedMaterialKeys, contains('장맛비'));
  });

  test('does not immediately reuse a material from the opening turn', () {
    const engine = LocalCasualConversationEngine();
    final ledger = ConversationUsageLedger();
    final openingContext = DailyOpeningContext(
      selectedCandidate: const DailyKeywordEntry(
        type: 'weather',
        keyword: '비',
        hint: '비가 내리는 날',
        plantHint: '창가의 빗소리를 들어보자',
        tone: 'gentle',
        fitScore: 0.8,
      ),
    );
    final materials = _materialContext(now, [
      DailyConversationMaterial(
        type: 'weather',
        keyword: '비',
        hint: '비가 내리는 날',
        plantHint: '창가의 빗소리를 들어보자',
        tone: 'gentle',
        fitScore: 0.8,
      ),
      DailyConversationMaterial(
        type: 'safe_issue',
        keyword: '독서',
        hint: '책 이야기를 나누는 날',
        plantHint: '조용한 시간을 함께 보내자',
        tone: 'calm',
        fitScore: 0.72,
      ),
    ]);

    final opening = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        now: now,
        dailyOpeningContext: openingContext,
        dailyConversationMaterialContext: materials,
        usageLedger: ledger,
        isOpeningTurn: true,
      ),
    );
    final next = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '오늘 뭐해?',
        now: now.add(const Duration(minutes: 1)),
        dailyOpeningContext: openingContext,
        dailyConversationMaterialContext: materials,
        usageLedger: ledger,
      ),
    );

    expect(opening.replyText, contains('비'));
    expect(next.replyText, contains('독서'));
    expect(next.replyText, isNot(contains('비가 내리는 날')));
  });

  test('rotates materials and falls back locally while all are cooling down', () {
    const engine = LocalCasualConversationEngine();
    final ledger = ConversationUsageLedger();
    final materials = _materialContext(now, [
      DailyConversationMaterial(
        type: 'weather',
        keyword: '비',
        hint: '비가 내리는 날',
        plantHint: '창가의 빗소리를 들어보자',
        tone: 'gentle',
        fitScore: 0.8,
      ),
      DailyConversationMaterial(
        type: 'safe_issue',
        keyword: '독서',
        hint: '책 이야기를 나누는 날',
        plantHint: '조용한 시간을 함께 보내자',
        tone: 'calm',
        fitScore: 0.72,
      ),
    ]);

    final responses = List.generate(
      3,
      (_) => engine.generate(
        ConversationRequest(
          plantId: 'plant-1',
          plantName: '무가리',
          userMessage: '오늘 뭐해?',
          now: now,
          dailyConversationMaterialContext: materials,
          usageLedger: ledger,
        ),
      ),
    );

    expect(responses[0].usedDailyKeyword, isTrue);
    expect(responses[1].usedDailyKeyword, isTrue);
    expect(responses[0].replyText, isNot(responses[1].replyText));
    expect(responses[2].usedDailyKeyword, isFalse);
    expect(responses.every((response) => response.usedApi == false), isTrue);
  });

  test('rotates repeated plain casual replies inside one session', () {
    const engine = LocalCasualConversationEngine();
    final ledger = ConversationUsageLedger();

    final replies = List.generate(
      5,
      (_) => engine
          .generate(
            ConversationRequest(
              plantId: 'plant-1',
              plantName: '무가리',
              userMessage: '기분 어때?',
              usageLedger: ledger,
            ),
          )
          .replyText,
    );

    expect(replies.toSet(), hasLength(5));
  });

  test('uses the current plant name with the correct Korean subject particle', () {
    const engine = LocalCasualConversationEngine();

    final vowelNameReply = engine.generate(
      const ConversationRequest(
        plantId: 'name-vowel',
        plantName: '몬스테라',
        userMessage: '뭐해?',
      ),
    );
    final batchimNameReply = engine.generate(
      const ConversationRequest(
        plantId: 'name-batchim',
        plantName: '봄',
        userMessage: '뭐해?',
      ),
    );

    expect(vowelNameReply.replyText, contains('몬스테라가 잎 정리하면서'));
    expect(batchimNameReply.replyText, contains('봄이 잎 정리하면서'));
    expect(vowelNameReply.replyText, isNot(contains('무가리')));
    expect(batchimNameReply.replyText, isNot(contains('무가리')));
  });

  test('applies request mood once without a fixed personality suffix', () {
    const engine = LocalCasualConversationEngine();
    final response = engine.generate(
      const ConversationRequest(
        plantId: 'id-0',
        plantName: '초록이',
        userMessage: '안녕',
        mood: '밝음',
        friendship: 10,
      ),
    );

    expect(
      response.replyText,
      anyOf(startsWith('좋아, '), startsWith('반가워. '), startsWith('오늘은 기분 좋게, ')),
    );
    expect(response.replyText, contains('초록이'));
    expect(response.replyText, isNot(contains('작게 말')));
  });

  test('uses a plain local reply when material context is absent', () {
    const engine = LocalCasualConversationEngine();
    final response = engine.generate(
      ConversationRequest(
        plantId: 'plant-1',
        plantName: '무가리',
        userMessage: '안녕',
        usageLedger: ConversationUsageLedger(),
      ),
    );

    expect(response.usedDailyKeyword, isFalse);
    expect(response.usedApi, isFalse);
    expect(response.replyText, isNotEmpty);
  });
}

DailyConversationMaterialContext _materialContext(
  DateTime date,
  List<DailyConversationMaterial> materials,
) {
  return DailyConversationMaterialContext(
    date: date,
    locale: 'ko-KR',
    sourceVersion: 'test-v1',
    materials: materials,
  );

  test('applies stored species character only through the local engine', () {
    const engine = LocalCasualConversationEngine();
    final response = engine.generate(
      const ConversationRequest(
        plantId: 'species-0',
        plantName: '초록이',
        userMessage: '안녕',
        species: '사용자가 바꾼 표시 이름',
        speciesKey: 'monstera',
      ),
    );

    expect(response.route, ConversationRoute.localCasual);
    expect(response.usedApi, isFalse);
    expect(response.replyText, startsWith('잎을 활짝 펼친 기분으로, '));
  });

}
