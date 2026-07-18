import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  group('DailyKeywordExtractionPolicy', () {
    test('extracts whitelist candidates into a valid v1 contract', () {
      final result = const DailyKeywordExtractionPolicy().extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [
          _document(
            title: '폭염 속 반려식물과 공원 산책',
            snippet: '여름에는 한낮 빛과 건조한 공기를 살펴요.',
          ),
        ],
      );

      expect(result.blockedDocumentCount, 0);
      expect(result.staleDocumentCount, 0);
      expect(result.unmatchedDocumentCount, 0);
      expect(
        result.candidates.map((candidate) => candidate.keyword),
        containsAll(['폭염', '건조', '반려식물']),
      );
      expect(
        result.candidates.every(
          (candidate) => (candidate.relevanceScore ?? 0) >= 0.60,
        ),
        isTrue,
      );

      final document = DailyKeywordContextDocument(
        date: DateTime.utc(2026, 7, 18),
        locale: 'ko-KR',
        regionCode: 'global',
        generatedAt: DateTime.utc(2026, 7, 18, 1),
        sourceVersion: 'collector-cr2d-test',
        keywords: result.candidates,
      );
      expect(
        const DailyKeywordContractValidator().validate(document).errors,
        isEmpty,
      );
    });

    test('rejects a whole document when blocked material is present', () {
      final result = const DailyKeywordExtractionPolicy().extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [
          _document(
            title: '공원 산책과 전쟁 관련 소식',
            snippet: '재활용 이야기도 포함되어 있습니다.',
          ),
        ],
      );

      expect(result.candidates, isEmpty);
      expect(result.blockedDocumentCount, 1);
    });

    test('rejects stale and implausibly future-dated documents', () {
      final policy = const DailyKeywordExtractionPolicy();
      final result = policy.extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [
          _document(
            title: '반려식물',
            publishedAt: DateTime.utc(2026, 7, 1),
            freshnessWindowDays: 7,
          ),
          _document(
            title: '재활용',
            publishedAt: DateTime.utc(2026, 7, 21),
          ),
        ],
      );

      expect(result.candidates, isEmpty);
      expect(result.staleDocumentCount, 2);
    });

    test('keeps the highest scored duplicate keyword', () {
      final result = const DailyKeywordExtractionPolicy().extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [
          _document(
            title: '반려식물',
            queryPriority: 60,
            url: 'https://example.com/low',
          ),
          _document(
            title: '반려식물',
            queryPriority: 100,
            url: 'https://example.com/high',
          ),
        ],
      );

      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.keyword, '반려식물');
      expect(result.candidates.single.relevanceScore, greaterThan(0.90));
    });

    test('prefers 장맛비 over the nested 비 keyword', () {
      final result = const DailyKeywordExtractionPolicy().extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [_document(title: '제주 장맛비와 습도')],
      );

      expect(
        result.candidates.map((candidate) => candidate.keyword),
        containsAll(['장맛비', '습도']),
      );
      expect(
        result.candidates.map((candidate) => candidate.keyword),
        isNot(contains('비')),
      );
    });

    test('caps output and preserves type diversity', () {
      final result = const DailyKeywordExtractionPolicy().extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [
          _document(title: '폭염 건조 습도 강풍 미세먼지'),
          _document(title: '반려식물 공원 산책 독서 전시회 재활용'),
          _document(title: '봄 여름 가을 겨울'),
        ],
      );

      expect(result.candidates, hasLength(8));
      final counts = <String, int>{};
      for (final candidate in result.candidates) {
        counts[candidate.type] = (counts[candidate.type] ?? 0) + 1;
      }
      expect(counts.values.every((count) => count <= 3), isTrue);
      expect(counts.keys, containsAll([
        DailyKeywordTypes.weather,
        DailyKeywordTypes.safeIssue,
        DailyKeywordTypes.seasonal,
      ]));
    });

    test('preserves optional age-band discovery metadata', () {
      final result = const DailyKeywordExtractionPolicy().extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [
          _document(
            title: '전시회와 독서',
            targetAgeBands: const [
              DailyKeywordAgeBands.thirties,
              DailyKeywordAgeBands.forties,
            ],
          ),
        ],
      );

      expect(result.candidates, isNotEmpty);
      expect(
        result.candidates.every(
          (candidate) =>
              candidate.targetAgeBands.length == 2 &&
              candidate.targetAgeBands.contains(
                DailyKeywordAgeBands.thirties,
              ),
        ),
        isTrue,
      );
    });

    test('counts unmatched documents without inventing candidates', () {
      final result = const DailyKeywordExtractionPolicy().extract(
        date: DateTime.utc(2026, 7, 18),
        documents: [_document(title: '가벼운 일상 이야기')],
      );

      expect(result.candidates, isEmpty);
      expect(result.unmatchedDocumentCount, 1);
    });

    test('rejects invalid policy limits', () {
      expect(
        () => const DailyKeywordExtractionPolicy(
          maximumCandidates: 9,
        ).extract(
          date: DateTime.utc(2026, 7, 18),
          documents: const [],
        ),
        throwsStateError,
      );
      expect(
        () => const DailyKeywordExtractionPolicy(
          maximumCandidates: 2,
          maximumPerType: 3,
        ).extract(
          date: DateTime.utc(2026, 7, 18),
          documents: const [],
        ),
        throwsStateError,
      );
    });
  });
}

SearchDocument _document({
  required String title,
  String snippet = '',
  int queryPriority = 90,
  int freshnessWindowDays = 7,
  DateTime? publishedAt,
  String url = 'https://example.com/material',
  Iterable<String> targetAgeBands = const [],
}) {
  return SearchDocument(
    source: SearchDocumentSources.web,
    queryId: 'safe-material',
    queryIntent: DailyQueryIntents.nature,
    queryText: '오늘 자연 식물',
    queryPriority: queryPriority,
    freshnessWindowDays: freshnessWindowDays,
    title: title,
    snippet: snippet,
    url: Uri.parse(url),
    publishedAt: publishedAt ?? DateTime.utc(2026, 7, 18, 12),
    targetAgeBands: targetAgeBands,
  );
}
