import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  group('DailyContextCollectorRunner', () {
    test('reports SUCCESS and assembles search plus local material', () async {
      final runner = DailyContextCollectorRunner(
        searchLoader: _Loader((query) async {
          if (query.id != 'nature-daily') {
            return const [];
          }
          return [_document(query, title: '오늘의 반려식물 이야기')];
        }),
      );

      final report = await runner.run(_request());

      expect(report.status, DailyCollectorRunStatus.success);
      expect(report.isDegraded, isFalse);
      expect(report.extractedCandidateCount, 1);
      expect(
        report.document.keywords.map((candidate) => candidate.keyword),
        containsAll(['반려식물', '여름']),
      );
      expect(report.toSummaryJson()['status'], 'SUCCESS');
    });

    test('reports EMPTY while retaining deterministic local fallback', () async {
      final runner = DailyContextCollectorRunner(
        searchLoader: _Loader((_) async => const []),
      );

      final report = await runner.run(_request());

      expect(report.status, DailyCollectorRunStatus.empty);
      expect(report.searchDocumentCount, 0);
      expect(report.extractedCandidateCount, 0);
      expect(
        report.document.keywords.map((candidate) => candidate.keyword),
        contains('여름'),
      );
      expect(report.toSummaryJson()['status'], 'EMPTY');
    });

    test('reports SOURCE_FAILED when every planned query fails', () async {
      final runner = DailyContextCollectorRunner(
        searchLoader: _Loader((_) => throw StateError('provider down')),
      );

      final report = await runner.run(_request());

      expect(report.status, DailyCollectorRunStatus.sourceFailed);
      expect(report.failedQueryIds, hasLength(6));
      expect(report.isDegraded, isTrue);
      expect(
        report.document.keywords.map((candidate) => candidate.keyword),
        contains('여름'),
      );
      expect(report.toSummaryJson()['status'], 'SOURCE_FAILED');
    });

    test('reports degraded SUCCESS when one query fails but material exists', () async {
      final runner = DailyContextCollectorRunner(
        searchLoader: _Loader((query) async {
          if (query.id == 'weather-daily') {
            throw StateError('weather endpoint down');
          }
          if (query.id == 'nature-daily') {
            return [_document(query, title: '반려식물과 재활용')];
          }
          return const [];
        }),
      );

      final report = await runner.run(_request());

      expect(report.status, DailyCollectorRunStatus.success);
      expect(report.failedQueryIds, ['weather-daily']);
      expect(report.isDegraded, isTrue);
      expect(report.extractedCandidateCount, 2);
    });

    test('does not mislabel partial failure with no candidates as EMPTY', () async {
      final runner = DailyContextCollectorRunner(
        searchLoader: _Loader((query) async {
          if (query.id == 'weather-daily') {
            throw StateError('provider timeout');
          }
          return const [];
        }),
      );

      final report = await runner.run(_request());

      expect(report.status, DailyCollectorRunStatus.sourceFailed);
      expect(report.extractedCandidateCount, 0);
      expect(report.failedQueryIds, ['weather-daily']);
    });

    test('treats mismatched query metadata as a source failure', () async {
      final runner = DailyContextCollectorRunner(
        searchLoader: _Loader((query) async {
          if (query.id != 'nature-daily') {
            return const [];
          }
          return [
            SearchDocument(
              source: SearchDocumentSources.web,
              queryId: 'weather-daily',
              queryIntent: DailyQueryIntents.weather,
              queryText: '오늘 날씨 생활',
              queryPriority: 100,
              freshnessWindowDays: 2,
              title: '반려식물',
              snippet: '',
              url: Uri.parse('https://example.com/mismatch'),
            ),
          ];
        }),
      );

      final report = await runner.run(_request());

      expect(report.status, DailyCollectorRunStatus.sourceFailed);
      expect(report.failedQueryIds, ['nature-daily']);
      expect(report.searchDocumentCount, 0);
    });

    test('summary contains counts but not document text or secrets', () async {
      final runner = DailyContextCollectorRunner(
        searchLoader: _Loader(
          (query) async => query.id == 'nature-daily'
              ? [_document(query, title: '공원 산책')]
              : const [],
        ),
      );

      final report = await runner.run(_request());
      final summary = report.toSummaryJson().toString();

      expect(summary, contains('searchDocumentCount'));
      expect(summary, isNot(contains('공원 산책')));
      expect(summary.toLowerCase(), isNot(contains('authorization')));
      expect(summary.toLowerCase(), isNot(contains('apikey')));
    });
  });
}

DailyCollectorRunRequest _request() {
  return DailyCollectorRunRequest(
    date: DateTime.utc(2026, 7, 18),
    locale: 'ko-KR',
    regionCode: 'global',
    generatedAt: DateTime.utc(2026, 7, 18, 1),
    sourceVersion: 'collector-cr2f-test',
  );
}

SearchDocument _document(
  DailySearchQuery query, {
  required String title,
}) {
  return SearchDocument.fromQuery(
    source: SearchDocumentSources.web,
    query: query,
    title: title,
    snippet: '가볍고 안전한 생활 자료',
    url: Uri.parse('https://example.com/${query.id}'),
    publishedAt: DateTime.utc(2026, 7, 18, 0, 30),
  );
}

final class _Loader implements SearchDocumentLoader {
  const _Loader(this.callback);

  final Future<List<SearchDocument>> Function(DailySearchQuery query) callback;

  @override
  Future<List<SearchDocument>> load(DailySearchQuery query) {
    return callback(query);
  }
}
