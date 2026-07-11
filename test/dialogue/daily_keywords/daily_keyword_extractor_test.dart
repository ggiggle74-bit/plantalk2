import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_extractor.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';

void main() {
  test('rejects invalid, unsafe, and low-quality candidates with a count', () {
    final candidates = [
      _candidate(keyword: ' '),
      _candidate(hint: ' '),
      _candidate(plantHint: ' '),
      _candidate(type: 'unsupported'),
      _candidate(tone: 'unsupported'),
      _candidate(fitScore: double.nan),
      _candidate(fitScore: double.infinity),
      _candidate(fitScore: -0.01),
      _candidate(fitScore: 1.01),
      _candidate(fitScore: 0.59),
      _candidate(keyword: '정치'),
    ];

    final result = const DailyKeywordExtractor().extract(candidates);

    expect(result.acceptedCandidates, isEmpty);
    expect(result.rejectedCount, candidates.length);
  });

  test('uses a configurable minimum fit score', () {
    final result = const DailyKeywordExtractor(minimumFitScore: 0.80).extract([
      _candidate(keyword: '낮은 점수', fitScore: 0.79),
      _candidate(keyword: '기준 점수', fitScore: 0.80),
    ]);

    expect(result.acceptedCandidates.map((candidate) => candidate.keyword), [
      '기준 점수',
    ]);
    expect(result.rejectedCount, 1);
  });

  test('removes normalized duplicates and preserves stable accepted order', () {
    final input = [
      _candidate(keyword: '비'),
      _candidate(keyword: '봄', type: DailyKeywordTypes.seasonal),
      _candidate(keyword: ' 비 '),
    ];

    final result = const DailyKeywordExtractor().extract(input);

    expect(result.acceptedCandidates.map((candidate) => candidate.keyword), [
      '비',
      '봄',
    ]);
    expect(result.rejectedCount, 1);
    expect(input, hasLength(3));
    expect(input.last.keyword, ' 비 ');
  });

  test('retains the configured source version', () {
    final result = const DailyKeywordExtractor(
      sourceVersion: 'test-v1',
    ).extract([_candidate()]);

    expect(result.sourceVersion, 'test-v1');
  });
}

DailyKeywordCandidate _candidate({
  String type = DailyKeywordTypes.weather,
  String keyword = '비',
  String hint = '비가 내리는 날',
  String plantHint = '창가 빛 변화를 살피기',
  String tone = DailyKeywordTones.gentle,
  double fitScore = 0.75,
}) {
  return DailyKeywordCandidate(
    type: type,
    keyword: keyword,
    hint: hint,
    plantHint: plantHint,
    tone: tone,
    fitScore: fitScore,
    category: 'rain',
  );
}
