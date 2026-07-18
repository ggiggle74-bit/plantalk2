import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  group('LocalCalendarSeasonSource', () {
    test('creates a fixed Korean commemorative day and season', () async {
      final candidates = await const LocalCalendarSeasonSource().load(
        DailyCandidateSourceRequest(
          date: DateTime.utc(2026, 4, 5),
          locale: 'ko-KR',
          regionCode: 'KR',
        ),
      );

      expect(
        candidates.map((candidate) => candidate.keyword),
        ['식목일', '봄'],
      );
      expect(
        candidates.every((candidate) => candidate.conversationAngles.isNotEmpty),
        isTrue,
      );
    });

    test('returns no local calendar material for another locale', () async {
      final candidates = await const LocalCalendarSeasonSource().load(
        DailyCandidateSourceRequest(
          date: DateTime.utc(2026, 4, 5),
          locale: 'en-US',
          regionCode: 'global',
        ),
      );

      expect(candidates, isEmpty);
    });
  });

  group('DailyKeywordContextAssembler', () {
    test('merges injected sources into a valid v1 document', () async {
      final assembler = DailyKeywordContextAssembler(
        sources: [
          const LocalCalendarSeasonSource(),
          SnapshotDailyCandidateSource(
            id: 'weather-snapshot',
            candidates: [
              _candidate(
                type: DailyKeywordTypes.weather,
                keyword: '폭염',
                relevanceScore: 0.95,
              ),
            ],
          ),
          SnapshotDailyCandidateSource(
            id: 'search-extraction',
            candidates: [
              _candidate(
                type: DailyKeywordTypes.safeIssue,
                keyword: '반려식물',
                relevanceScore: 0.90,
              ),
            ],
          ),
        ],
      );

      final result = await assembler.assemble(_request());

      expect(result.failedSourceIds, isEmpty);
      expect(result.rejectedCandidateCount, 0);
      expect(
        result.document.keywords.map((candidate) => candidate.keyword),
        containsAll(['여름', '폭염', '반려식물']),
      );
      expect(
        const DailyKeywordContractValidator()
            .validate(result.document)
            .isValid,
        isTrue,
      );
    });

    test('isolates a failed source and keeps healthy results', () async {
      final assembler = DailyKeywordContextAssembler(
        sources: [
          const _FailingSource('weather-remote'),
          SnapshotDailyCandidateSource(
            id: 'local-fallback',
            candidates: [
              _candidate(
                type: DailyKeywordTypes.safeIssue,
                keyword: '재활용',
              ),
            ],
          ),
        ],
      );

      final result = await assembler.assemble(_request());

      expect(result.failedSourceIds, ['weather-remote']);
      expect(result.document.keywords.single.keyword, '재활용');
    });

    test('drops a candidate that fails the final v1 contract', () async {
      final assembler = DailyKeywordContextAssembler(
        sources: [
          SnapshotDailyCandidateSource(
            id: 'invalid-source',
            candidates: [
              _candidate(
                type: DailyKeywordTypes.safeIssue,
                keyword: '낮은 점수',
                fitScore: 0.20,
                relevanceScore: 0.20,
              ),
            ],
          ),
        ],
      );

      final result = await assembler.assemble(_request());

      expect(result.document.keywords, isEmpty);
      expect(result.rejectedCandidateCount, 1);
    });

    test('keeps the highest-quality duplicate candidate', () async {
      final assembler = DailyKeywordContextAssembler(
        sources: [
          SnapshotDailyCandidateSource(
            id: 'first-source',
            candidates: [
              _candidate(
                type: DailyKeywordTypes.weather,
                keyword: '폭염',
                relevanceScore: 0.70,
              ),
            ],
          ),
          SnapshotDailyCandidateSource(
            id: 'second-source',
            candidates: [
              _candidate(
                type: DailyKeywordTypes.weather,
                keyword: '  폭염 ',
                relevanceScore: 0.96,
              ),
            ],
          ),
        ],
      );

      final result = await assembler.assemble(_request());

      expect(result.document.keywords, hasLength(1));
      expect(result.document.keywords.single.relevanceScore, 0.96);
    });

    test('caps the document and preserves per-type diversity', () async {
      final candidates = <DailyKeywordCandidate>[
        for (var index = 0; index < 5; index++)
          _candidate(
            type: DailyKeywordTypes.weather,
            keyword: '날씨-$index',
            relevanceScore: 0.99 - (index * 0.01),
          ),
        for (var index = 0; index < 5; index++)
          _candidate(
            type: DailyKeywordTypes.safeIssue,
            keyword: '생활-$index',
            relevanceScore: 0.90 - (index * 0.01),
          ),
        for (var index = 0; index < 3; index++)
          _candidate(
            type: DailyKeywordTypes.seasonal,
            keyword: '계절-$index',
            relevanceScore: 0.80 - (index * 0.01),
          ),
      ];
      final assembler = DailyKeywordContextAssembler(
        sources: [
          SnapshotDailyCandidateSource(
            id: 'many-candidates',
            candidates: candidates,
          ),
        ],
      );

      final result = await assembler.assemble(_request());

      expect(result.document.keywords, hasLength(8));
      final typeCounts = <String, int>{};
      for (final candidate in result.document.keywords) {
        typeCounts[candidate.type] = (typeCounts[candidate.type] ?? 0) + 1;
      }
      expect(typeCounts.values.every((count) => count <= 3), isTrue);
      expect(typeCounts.keys, hasLength(3));
    });

    test('produces a valid empty document when all sources are empty', () async {
      final assembler = DailyKeywordContextAssembler(
        sources: [
          SnapshotDailyCandidateSource(
            id: 'empty-source',
            candidates: const [],
          ),
        ],
      );

      final result = await assembler.assemble(_request());

      expect(result.document.keywords, isEmpty);
      expect(
        const DailyKeywordContractValidator()
            .validate(result.document)
            .isValid,
        isTrue,
      );
    });

    test('rejects duplicate source IDs before assembly', () {
      expect(
        () => DailyKeywordContextAssembler(
          sources: [
            SnapshotDailyCandidateSource(
              id: 'same-source',
              candidates: const [],
            ),
            SnapshotDailyCandidateSource(
              id: 'same-source',
              candidates: const [],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

DailyContextAssemblyRequest _request() {
  return DailyContextAssemblyRequest(
    date: DateTime.utc(2026, 7, 18),
    locale: 'ko-KR',
    regionCode: 'KR-49',
    generatedAt: DateTime.utc(2026, 7, 18, 1),
    sourceVersion: 'collector-cr2e-test',
  );
}

DailyKeywordCandidate _candidate({
  required String type,
  required String keyword,
  double fitScore = 0.80,
  double relevanceScore = 0.80,
}) {
  return DailyKeywordCandidate(
    type: type,
    keyword: keyword,
    hint: '$keyword 관련 가벼운 이야기',
    plantHint: '식물 주변을 천천히 살피기',
    tone: DailyKeywordTones.gentle,
    fitScore: fitScore,
    relevanceScore: relevanceScore,
    category: 'test',
    conversationAngles: ['$keyword 분위기 살피기'],
  );
}

final class _FailingSource implements DailyCandidateSource {
  const _FailingSource(this.id);

  @override
  final String id;

  @override
  Future<List<DailyKeywordCandidate>> load(
    DailyCandidateSourceRequest request,
  ) {
    throw StateError('fixture failure');
  }
}
