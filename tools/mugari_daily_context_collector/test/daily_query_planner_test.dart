import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  group('DailyQueryPlanner', () {
    test('builds a deterministic safe general query plan', () {
      final request = DailyQueryPlanRequest(
        date: DateTime.utc(2026, 7, 18),
        locale: 'ko-KR',
      );
      const planner = DailyQueryPlanner();

      final first = planner.plan(request);
      final second = planner.plan(request);

      expect(first.toJson(), equals(second.toJson()));
      expect(first.queries, hasLength(6));
      expect(first.queries.map((query) => query.id), [
        'weather-daily',
        'nature-daily',
        'seasonal-monthly',
        'park-weekly',
        'environment-weekly',
        'culture-weekly',
      ]);
      expect(
        first.queries
            .singleWhere((query) => query.id == 'seasonal-monthly')
            .text,
        '7월 여름 계절 식물',
      );
      expect(first.toJson()['date'], '2026-07-18');
      expect(
        first.queries.every((query) => query.targetAgeBands.isEmpty),
        isTrue,
      );

      final ids = first.queries.map((query) => query.id).toSet();
      final texts = first.queries.map((query) => query.text).toSet();
      expect(ids, hasLength(first.queries.length));
      expect(texts, hasLength(first.queries.length));

      const forbiddenTerms = [
        '뉴스',
        '실시간',
        '사건',
        '사고',
        '정치',
        '범죄',
        '전쟁',
      ];
      for (final query in first.queries) {
        for (final term in forbiddenTerms) {
          expect(query.text, isNot(contains(term)));
        }
      }
    });

    test('adds one normalized region query only for a local context', () {
      final request = DailyQueryPlanRequest(
        date: DateTime.utc(2026, 7, 18),
        locale: 'ko-KR',
        regionCode: 'KR-11-680',
        regionLabel: '  서울   강남구  ',
      );

      final plan = const DailyQueryPlanner().plan(request);
      final regionQuery = plan.queries.singleWhere(
        (query) => query.intent == DailyQueryIntents.region,
      );

      expect(request.regionLabel, '서울 강남구');
      expect(regionQuery.text, '서울 강남구 이번 주 공원 문화 행사');
      expect(regionQuery.regionScoped, isTrue);
      expect(plan.queries, hasLength(7));
    });

    test('canonicalizes age bands and rotates two audience queries by date', () {
      final request = DailyQueryPlanRequest(
        date: DateTime.utc(2026, 7, 18),
        locale: 'ko-KR',
        targetAgeBands: const [
          DailyKeywordAgeBands.sixtiesPlus,
          DailyKeywordAgeBands.teens,
          DailyKeywordAgeBands.twenties,
          DailyKeywordAgeBands.thirties,
          DailyKeywordAgeBands.forties,
          DailyKeywordAgeBands.fifties,
          DailyKeywordAgeBands.teens,
        ],
      );
      const planner = DailyQueryPlanner();

      final first = planner.plan(request);
      final repeated = planner.plan(request);
      final nextDay = planner.plan(
        DailyQueryPlanRequest(
          date: DateTime.utc(2026, 7, 19),
          locale: 'ko-KR',
          targetAgeBands: request.targetAgeBands,
        ),
      );
      final audience = first.queries
          .where((query) => query.intent == DailyQueryIntents.audience)
          .toList();
      final repeatedAudience = repeated.queries
          .where((query) => query.intent == DailyQueryIntents.audience)
          .map((query) => query.targetAgeBands.single)
          .toList();
      final nextAudience = nextDay.queries
          .where((query) => query.intent == DailyQueryIntents.audience)
          .map((query) => query.targetAgeBands.single)
          .toList();

      expect(request.targetAgeBands, DailyKeywordAgeBands.allowed.toList());
      expect(audience, hasLength(2));
      expect(
        audience.map((query) => query.targetAgeBands.single).toList(),
        repeatedAudience,
      );
      expect(nextAudience, isNot(repeatedAudience));
      for (final query in audience) {
        expect(query.targetAgeBands, hasLength(1));
        expect(
          DailyKeywordAgeBands.allowed,
          contains(query.targetAgeBands.single),
        );
        expect(query.text, contains('취미 문화 산책'));
      }
    });

    test('keeps all queries age-neutral when no age bands are requested', () {
      final plan = const DailyQueryPlanner().plan(
        DailyQueryPlanRequest(
          date: DateTime.utc(2026, 2, 5),
          locale: 'ko-KR',
        ),
      );

      expect(
        plan.queries.where(
          (query) => query.intent == DailyQueryIntents.audience,
        ),
        isEmpty,
      );
      expect(
        plan.queries.every((query) => query.targetAgeBands.isEmpty),
        isTrue,
      );
    });

    test('rejects unsupported age bands and ambiguous region metadata', () {
      expect(
        () => DailyQueryPlanRequest(
          date: DateTime.utc(2026, 7, 18),
          locale: 'ko-KR',
          targetAgeBands: const ['children'],
        ),
        throwsArgumentError,
      );
      expect(
        () => DailyQueryPlanRequest(
          date: DateTime.utc(2026, 7, 18),
          locale: 'ko-KR',
          regionLabel: '서울',
        ),
        throwsArgumentError,
      );
    });

    test('supports a deterministic English fallback plan', () {
      final plan = const DailyQueryPlanner().plan(
        DailyQueryPlanRequest(
          date: DateTime.utc(2026, 12, 2),
          locale: 'en-US',
        ),
      );

      expect(plan.queries.first.text, 'today weather daily life');
      expect(
        plan.queries
            .singleWhere((query) => query.id == 'seasonal-monthly')
            .text,
        'December winter seasonal plants',
      );
    });

    test('caps the final query count after priority ordering', () {
      final plan = const DailyQueryPlanner(
        maximumQueries: 7,
        maximumAudienceQueries: 6,
      ).plan(
        DailyQueryPlanRequest(
          date: DateTime.utc(2026, 7, 18),
          locale: 'ko-KR',
          regionCode: 'KR-11',
          regionLabel: '서울',
          targetAgeBands: DailyKeywordAgeBands.allowed,
        ),
      );

      expect(plan.queries, hasLength(7));
      expect(
        plan.queries.any((query) => query.intent == DailyQueryIntents.region),
        isTrue,
      );
      expect(
        plan.queries.where(
          (query) => query.intent == DailyQueryIntents.audience,
        ),
        isEmpty,
      );
    });
  });

  group('SearchDocument', () {
    test('round-trips normalized search-result and query metadata', () {
      final query = DailySearchQuery(
        id: 'nature-daily',
        text: '  오늘   자연 식물  ',
        intent: DailyQueryIntents.nature,
        priority: 95,
        freshnessWindowDays: 7,
        targetAgeBands: const [
          DailyKeywordAgeBands.thirties,
          DailyKeywordAgeBands.twenties,
        ],
      );
      final document = SearchDocument.fromQuery(
        source: SearchDocumentSources.web,
        query: query,
        title: '<b>공원</b> 산책',
        snippet: '비 &amp; 바람 속 자연 관찰',
        url: Uri.parse('https://example.com/material/1'),
        publishedAt: DateTime.parse('2026-07-18T14:00:00+09:00'),
      );

      final decoded = SearchDocument.fromJson(document.toJson());

      expect(document.queryText, '오늘 자연 식물');
      expect(document.queryPriority, 95);
      expect(document.freshnessWindowDays, 7);
      expect(document.title, '공원 산책');
      expect(document.snippet, '비 바람 속 자연 관찰');
      expect(document.publishedAt, DateTime.utc(2026, 7, 18, 5));
      expect(document.targetAgeBands, [
        DailyKeywordAgeBands.twenties,
        DailyKeywordAgeBands.thirties,
      ]);
      expect(decoded.toJson(), document.toJson());
    });

    test('rejects unsupported sources, unsafe URLs, and empty documents', () {
      expect(
        () => _searchDocument(source: 'social'),
        throwsArgumentError,
      );
      expect(
        () => _searchDocument(url: Uri.parse('file:///tmp/material.html')),
        throwsArgumentError,
      );
      expect(
        () => _searchDocument(title: '', snippet: ''),
        throwsArgumentError,
      );
    });
  });
}

SearchDocument _searchDocument({
  String source = SearchDocumentSources.web,
  Uri? url,
  String title = '제목',
  String snippet = '',
}) {
  return SearchDocument(
    source: source,
    queryId: 'nature-daily',
    queryIntent: DailyQueryIntents.nature,
    queryText: '오늘 자연 식물',
    queryPriority: 95,
    freshnessWindowDays: 7,
    title: title,
    snippet: snippet,
    url: url ?? Uri.parse('https://example.com'),
  );
}
