import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_extraction_result.dart';

void main() {
  test('stores immutable candidate metadata with machine-readable values', () {
    const candidate = DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '비',
      hint: '비가 내리는 날',
      plantHint: '창가 빛 변화를 살피기',
      tone: DailyKeywordTones.gentle,
      fitScore: 0.75,
      category: 'rain',
    );

    expect(candidate.type, DailyKeywordTypes.weather);
    expect(candidate.tone, DailyKeywordTones.gentle);
    expect(candidate.fitScore, 0.75);
  });

  test('retains an unmodifiable extraction result list', () {
    const candidate = DailyKeywordCandidate(
      type: DailyKeywordTypes.seasonal,
      keyword: '봄',
      hint: '봄기운이 느껴지는 때',
      plantHint: '새 잎을 가볍게 바라보기',
      tone: DailyKeywordTones.bright,
      fitScore: 0.70,
    );
    final result = DailyKeywordExtractionResult(
      acceptedCandidates: [candidate],
      rejectedCount: 1,
      sourceVersion: 'cr1-static-v1',
    );

    expect(result.hasCandidates, isTrue);
    expect(result.rejectedCount, 1);
    expect(
      () => result.acceptedCandidates.add(candidate),
      throwsUnsupportedError,
    );
  });
}
