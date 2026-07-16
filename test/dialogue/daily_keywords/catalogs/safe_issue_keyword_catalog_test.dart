import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/catalogs/safe_issue_keyword_catalog.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_extractor.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';

void main() {
  test('whitelist entries have complete safe metadata', () {
    expect(
      SafeIssueKeywordCatalog.entries.map((entry) => entry.keyword),
      containsAll(<String>[
        '반려식물',
        '공원 산책',
        '독서',
        '전시회',
        '분리배출',
        '재활용',
        '제로웨이스트',
        '플로깅',
      ]),
    );

    for (final entry in SafeIssueKeywordCatalog.entries) {
      expect(entry.keyword.trim(), isNotEmpty);
      expect(entry.hint.trim(), isNotEmpty);
      expect(entry.plantHint.trim(), isNotEmpty);
      expect(DailyKeywordTones.allowed, contains(entry.tone));
      expect(entry.fitScore.isFinite, isTrue);
      expect(entry.fitScore, inInclusiveRange(0.0, 1.0));
      expect(entry.type, DailyKeywordTypes.safeIssue);
      expect(entry.category, isNotEmpty);
    }
  });

  test('all whitelist entries pass the shared extractor policy', () {
    final result = const DailyKeywordExtractor().extract(
      SafeIssueKeywordCatalog.entries,
    );

    expect(result.rejectedCount, 0);
    expect(
      result.acceptedCandidates.map((candidate) => candidate.keyword).toList(),
      SafeIssueKeywordCatalog.entries.map((entry) => entry.keyword).toList(),
    );
  });

  test('matches only normalized supplied safe signals in stable order', () {
    final candidates = SafeIssueKeywordCatalog.candidatesFor([
      '  분리배출  ',
      '분리배출',
      '',
      '환율 급등',
      '공원 산책',
      '대통령 선거',
    ]);

    expect(candidates.map((candidate) => candidate.keyword), [
      '분리배출',
      '공원 산책',
    ]);
  });

  test('unknown and heavy issue signals produce no candidates', () {
    expect(
      SafeIssueKeywordCatalog.candidatesFor([
        '',
        '   ',
        '대통령 선거',
        '살인 사건',
        '대형 사고',
        '충격 사건',
      ]),
      isEmpty,
    );
  });
}
