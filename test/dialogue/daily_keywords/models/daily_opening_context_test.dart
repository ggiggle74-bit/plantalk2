import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_opening_keyword_selector.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_opening_context.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  const candidate = DailyKeywordEntry(
    type: DailyKeywordTypes.weather,
    keyword: '비',
    hint: '비가 내리는 날',
    plantHint: '창가 빛 변화를 살피기',
    tone: DailyKeywordTones.gentle,
    fitScore: 0.82,
  );

  test('starts as an unconsumed first-greeting-only projection', () {
    final context = DailyOpeningContext(selectedCandidate: candidate);

    expect(context.selectedCandidate, same(candidate));
    expect(context.firstGreetingOnly, isTrue);
    expect(context.isConsumed, isFalse);
    expect(context.consumedAt, isNull);
  });

  test('consumes the selected candidate exactly once on the opening turn', () {
    final context = DailyOpeningContext(selectedCandidate: candidate);
    final consumedAt = DateTime.utc(2026, 7, 18, 9);

    expect(
      context.consume(isOpeningTurn: true, consumedAt: consumedAt),
      same(candidate),
    );
    expect(context.isConsumed, isTrue);
    expect(context.consumedAt, consumedAt);
    expect(
      context.consume(
        isOpeningTurn: true,
        consumedAt: consumedAt.add(const Duration(minutes: 1)),
      ),
      isNull,
    );
    expect(context.consumedAt, consumedAt);
  });

  test('does not consume or expose the candidate on a later turn', () {
    final context = DailyOpeningContext(selectedCandidate: candidate);

    expect(
      context.consume(
        isOpeningTurn: false,
        consumedAt: DateTime.utc(2026, 7, 18, 9),
      ),
      isNull,
    );
    expect(context.isConsumed, isFalse);
    expect(context.consumedAt, isNull);
  });

  test('selector projects one eligible candidate into a consumable context', () {
    const selector = DailyOpeningKeywordSelector();
    final now = DateTime.utc(2026, 7, 18);
    final projected = selector.project(
      context: DailyKeywordContext(
        date: now,
        locale: 'ko-KR',
        keywords: const [candidate],
      ),
      now: now,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(projected, isNotNull);
    expect(projected!.selectedCandidate, same(candidate));
    expect(
      projected.consume(isOpeningTurn: true, consumedAt: now),
      same(candidate),
    );
    expect(
      projected.consume(isOpeningTurn: true, consumedAt: now),
      isNull,
    );
  });

  test('selector does not create a projection outside the opening turn', () {
    const selector = DailyOpeningKeywordSelector();
    final now = DateTime.utc(2026, 7, 18);

    expect(
      selector.project(
        context: DailyKeywordContext(
          date: now,
          locale: 'ko-KR',
          keywords: const [candidate],
        ),
        now: now,
        isOpeningTurn: false,
        seed: 0,
      ),
      isNull,
    );
  });
}
