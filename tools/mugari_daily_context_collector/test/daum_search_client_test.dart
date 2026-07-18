import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  group('DaumSearchClient', () {
    test('maps a web fixture and sends the documented request shape', () async {
      SearchHttpRequest? captured;
      final client = DaumSearchClient(
        restApiKey: 'fixture-rest-key',
        transport: (request) async {
          captured = request;
          return SearchHttpResponse(
            statusCode: 200,
            body: File(
              'test/fixtures/daum_web_success.json',
            ).readAsStringSync(),
          );
        },
      );
      final query = _query();

      final result = await client.searchWeb(
        query,
        page: 2,
        size: 15,
        sort: 'recency',
      );

      expect(captured!.uri.scheme, 'https');
      expect(captured!.uri.host, 'dapi.kakao.com');
      expect(captured!.uri.path, '/v2/search/web');
      expect(captured!.uri.queryParameters, {
        'query': query.text,
        'sort': 'recency',
        'page': '2',
        'size': '15',
      });
      expect(
        captured!.headers['Authorization'],
        'KakaoAK fixture-rest-key',
      );
      expect(result.totalCount, 2);
      expect(result.pageableCount, 2);
      expect(result.isEnd, isTrue);
      expect(result.documents, hasLength(2));
      expect(result.documents.first.source, SearchDocumentSources.web);
      expect(result.documents.first.title, '서울숲 여름 산책');
      expect(
        result.documents.first.publishedAt,
        DateTime.utc(2026, 7, 18, 0, 30),
      );
      expect(result.documents.first.queryId, query.id);
      expect(result.documents.first.targetAgeBands, query.targetAgeBands);
    });

    test('maps a blog fixture without leaking provider-only fields', () async {
      final client = DaumSearchClient(
        restApiKey: 'fixture-rest-key',
        transport: (_) async => SearchHttpResponse(
          statusCode: 200,
          body: File(
            'test/fixtures/daum_blog_success.json',
          ).readAsStringSync(),
        ),
      );

      final result = await client.searchBlog(_query());

      expect(result.documents, hasLength(2));
      expect(result.documents.first.source, SearchDocumentSources.blog);
      expect(result.documents.first.title, '비 오는 날 반려식물 돌보기');
      expect(
        result.documents.first.toJson().keys,
        isNot(contains('blogname')),
      );
    });

    test('rejects page, size, and sort values outside provider limits', () async {
      final client = _client((_) async {
        fail('transport must not be called');
      });

      await expectLater(
        client.searchWeb(_query(), page: 0),
        throwsArgumentError,
      );
      await expectLater(
        client.searchWeb(_query(), size: 51),
        throwsArgumentError,
      );
      await expectLater(
        client.searchWeb(_query(), sort: 'popular'),
        throwsArgumentError,
      );
    });

    test('turns provider failures into a sanitized exception', () async {
      const secret = 'fixture-rest-key';
      final client = DaumSearchClient(
        restApiKey: secret,
        transport: (_) async => const SearchHttpResponse(
          statusCode: 401,
          body: '{"message":"unauthorized"}',
        ),
      );

      Object? captured;
      try {
        await client.searchWeb(_query());
      } catch (error) {
        captured = error;
      }

      expect(captured, isA<DaumSearchException>());
      expect(captured.toString(), contains('401'));
      expect(captured.toString(), isNot(contains(secret)));
      expect(captured.toString(), isNot(contains('unauthorized')));
    });

    test('rejects malformed JSON and malformed document payloads', () async {
      final malformedJson = _client(
        (_) async => const SearchHttpResponse(
          statusCode: 200,
          body: 'not-json',
        ),
      );
      final malformedDocument = _client(
        (_) async => const SearchHttpResponse(
          statusCode: 200,
          body: '{"meta":{"total_count":1,"pageable_count":1,'
              '"is_end":true},"documents":[{"title":"missing fields"}]}',
        ),
      );

      await expectLater(
        malformedJson.searchWeb(_query()),
        throwsA(isA<DaumSearchException>()),
      );
      await expectLater(
        malformedDocument.searchWeb(_query()),
        throwsA(isA<DaumSearchException>()),
      );
    });

    test('requires an injected non-empty API key', () {
      expect(
        () => DaumSearchClient(
          restApiKey: '  ',
          transport: (_) async => const SearchHttpResponse(
            statusCode: 200,
            body: '{}',
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

DaumSearchClient _client(SearchHttpTransport transport) {
  return DaumSearchClient(
    restApiKey: 'fixture-rest-key',
    transport: transport,
  );
}

DailySearchQuery _query() {
  return DailySearchQuery(
    id: 'nature-daily',
    text: '오늘 자연 식물',
    intent: DailyQueryIntents.nature,
    priority: 95,
    freshnessWindowDays: 7,
    targetAgeBands: const [DailyKeywordAgeBands.thirties],
  );
}
