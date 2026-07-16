import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_opening_keyword_selector.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  const selector = DailyOpeningKeywordSelector();
  final today = DateTime.utc(2026, 7, 16);

  test('returns no keyword without a usable opening context', () {
    expect(
      selector.select(
        context: null,
        now: today,
        isOpeningTurn: true,
        seed: 0,
      ),
      isNull,
    );
    expect(
      selector.select(
        context: _context(today, const []),
        now: today,
        isOpeningTurn: true,
        seed: 0,
      ),
      isNull,
    );
    expect(
      selector.select(
        context: _context(today, const [_rain]),
        now: today,
        isOpeningTurn: false,
        seed: 0,
      ),
      isNull,
    );
  });

  test('rejects a context from a different calendar date', () {
    final selected = selector.select(
      context: _context(DateTime.utc(2026, 7, 15), const [_rain]),
      now: today,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(selected, isNull);
  });

  test('selects one eligible entry deterministically from a daily context', () {
    final context = _context(today, const [_rain, _reading, _recycling]);

    expect(
      selector
          .select(
            context: context,
            now: today,
            isOpeningTurn: true,
            seed: 0,
          )
          ?.keyword,
      '비',
    );
    expect(
      selector
          .select(
            context: context,
            now: today,
            isOpeningTurn: true,
            seed: 1,
          )
          ?.keyword,
      '독서',
    );
    expect(
      selector
          .select(
            context: context,
            now: today,
            isOpeningTurn: true,
            seed: -1,
          )
          ?.keyword,
      '독서',
    );
  });

  test('filters blocked, unsupported, malformed, and low-score entries', () {
    final selected = selector.select(
      context: _context(today, const [
        DailyKeywordEntry(
          type: DailyKeywordTypes.safeIssue,
          keyword: '대통령 선거',
          hint: '무거운 정치 소식',
          fitScore: 0.90,
        ),
        DailyKeywordEntry(
          type: 'finance',
          keyword: '환율',
          hint: '금융 시장 이야기',
          fitScore: 0.90,
        ),
        DailyKeywordEntry(
          type: DailyKeywordTypes.weather,
          keyword: '미세먼지',
          hint: '공기 상태를 살펴요',
          tone: 'unsupported',
          fitScore: 0.90,
        ),
        DailyKeywordEntry(
          type: DailyKeywordTypes.weather,
          keyword: '강풍',
          hint: '바람이 거센 날',
          fitScore: 0.59,
        ),
        _recycling,
      ]),
      now: today,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(selected?.keyword, '재활용');
  });

  test('accepts legacy entries whose optional metadata is absent', () {
    const legacyEntry = DailyKeywordEntry(
      type: DailyKeywordTypes.weather,
      keyword: '비',
      hint: '비가 내리는 날',
    );

    final selected = selector.select(
      context: _context(today, const [legacyEntry]),
      now: today,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(selected, same(legacyEntry));
  });

  test('honors a stricter configurable fit-score threshold', () {
    const strictSelector = DailyOpeningKeywordSelector(
      minimumFitScore: 0.80,
    );

    final selected = strictSelector.select(
      context: _context(today, const [_reading, _rain]),
      now: today,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(selected?.keyword, '비');
  });

  test('does not mutate the context keyword order', () {
    final context = _context(today, const [_rain, _reading, _recycling]);
    final before = context.keywords.map((entry) => entry.keyword).toList();

    selector.select(
      context: context,
      now: today,
      isOpeningTurn: true,
      seed: 2,
    );

    expect(context.keywords.map((entry) => entry.keyword), before);
  });
}

DailyKeywordContext _context(
  DateTime date,
  List<DailyKeywordEntry> keywords,
) {
  return DailyKeywordContext(
    date: date,
    locale: 'ko-KR',
    keywords: keywords,
  );
}

const _rain = DailyKeywordEntry(
  type: DailyKeywordTypes.weather,
  keyword: '비',
  hint: '비가 내리는 날',
  plantHint: '창가 빛 변화를 살피기',
  tone: DailyKeywordTones.gentle,
  fitScore: 0.82,
);

const _reading = DailyKeywordEntry(
  type: DailyKeywordTypes.safeIssue,
  keyword: '독서',
  hint: '책 한 권을 천천히 읽는 이야기',
  plantHint: '조용한 시간을 함께 보내기',
  tone: DailyKeywordTones.calm,
  fitScore: 0.68,
);

const _recycling = DailyKeywordEntry(
  type: DailyKeywordTypes.safeIssue,
  keyword: '재활용',
  hint: '생활 속 재활용을 돌아보는 이야기',
  plantHint: '오래 쓰는 물건을 함께 떠올리기',
  tone: DailyKeywordTones.gentle,
  fitScore: 0.70,
);
