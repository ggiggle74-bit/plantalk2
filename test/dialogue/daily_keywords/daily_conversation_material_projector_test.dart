import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_conversation_material_projector.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  final today = DateTime.utc(2026, 7, 28);

  test('projects a bounded unique same-day material pool', () {
    final context = DailyKeywordContext(
      date: today,
      locale: 'ko-KR',
      generatedAt: DateTime.utc(2026, 7, 28, 1),
      sourceVersion: 'collector-cr2o',
      keywords: const [
        DailyKeywordEntry(
          type: 'weather',
          keyword: '비',
          hint: '비가 내리는 날',
          category: 'rain',
          relevanceScore: 0.91,
          plantHint: '창가의 빗소리를 함께 듣기',
          tone: 'gentle',
          fitScore: 0.82,
          targetAgeBands: ['10s'],
        ),
        DailyKeywordEntry(
          type: 'weather',
          keyword: '비',
          hint: '중복 소재',
          plantHint: '중복 소재는 제외하기',
          tone: 'calm',
          fitScore: 0.80,
        ),
        DailyKeywordEntry(
          type: 'seasonal',
          keyword: '여름',
          hint: '여름 기운이 이어지는 날',
          plantHint: '시원한 빛을 바라보기',
          tone: 'bright',
          fitScore: 0.76,
        ),
        DailyKeywordEntry(
          type: 'safe_issue',
          keyword: '독서',
          hint: '책 이야기를 나누는 날',
          plantHint: '조용한 시간을 함께 보내기',
          tone: 'calm',
          fitScore: 0.72,
        ),
      ],
    );
    const projector = DailyConversationMaterialProjector(
      maximumMaterials: 2,
    );

    final result = projector.project(context: context, now: today);

    expect(result, isNotNull);
    expect(result!.materials.map((material) => material.keyword), ['비', '여름']);
    expect(result.date, today);
    expect(result.locale, 'ko-KR');
    expect(result.generatedAt, DateTime.utc(2026, 7, 28, 1));
    expect(result.sourceVersion, 'collector-cr2o');
    expect(result.materials.first.plantHint, '창가의 빗소리를 함께 듣기');
    expect(result.materials.first.targetAgeBands, ['10s']);
  });

  test('returns null for a stale source context', () {
    final context = _context(
      date: today.subtract(const Duration(days: 1)),
      entries: [_validEntry()],
    );

    final result = const DailyConversationMaterialProjector().project(
      context: context,
      now: today,
    );

    expect(result, isNull);
  });

  test('filters incomplete blocked unsupported and low-fit entries', () {
    final context = _context(
      date: today,
      entries: [
        _validEntry(keyword: '산책'),
        _validEntry(keyword: '범죄 사건'),
        _validEntry(keyword: '낮은 점수', fitScore: 0.59),
        const DailyKeywordEntry(
          type: 'unsupported',
          keyword: '지원하지 않는 유형',
          hint: '잘못된 유형',
          plantHint: '사용하지 않기',
          tone: 'calm',
          fitScore: 0.8,
        ),
        const DailyKeywordEntry(
          type: 'safe_issue',
          keyword: '불완전',
          hint: '식물 연결 문장이 없음',
          tone: 'calm',
          fitScore: 0.8,
        ),
      ],
    );

    final result = const DailyConversationMaterialProjector().project(
      context: context,
      now: today,
    );

    expect(result, isNotNull);
    expect(result!.materials.map((material) => material.keyword), ['산책']);
  });

  test('returns null when no eligible material remains', () {
    final context = _context(
      date: today,
      entries: [_validEntry(keyword: '범죄 사건')],
    );

    final result = const DailyConversationMaterialProjector().project(
      context: context,
      now: today,
    );

    expect(result, isNull);
  });
}

DailyKeywordContext _context({
  required DateTime date,
  required List<DailyKeywordEntry> entries,
}) {
  return DailyKeywordContext(
    date: date,
    locale: 'ko-KR',
    sourceVersion: 'test-v1',
    keywords: entries,
  );
}

DailyKeywordEntry _validEntry({
  String keyword = '비',
  double fitScore = 0.8,
}) {
  return DailyKeywordEntry(
    type: 'safe_issue',
    keyword: keyword,
    hint: '가볍게 나눌 수 있는 오늘의 이야기',
    plantHint: '식물과 함께 조용히 바라보기',
    tone: 'gentle',
    fitScore: fitScore,
  );
}
