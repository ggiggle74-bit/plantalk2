import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

import '../bin/src/dart_io_search_http_transport.dart';

void main() {
  group('DaumSearchDocumentLoader', () {
    test('uses web recency search for weather', () async {
      SearchHttpRequest? captured;
      final loader = _loader((request) async {
        captured = request;
        return _emptyResponse();
      });

      final documents = await loader.load(
        _query('weather-daily', DailyQueryIntents.weather),
      );

      expect(documents, isEmpty);
      expect(captured!.uri.path, '/v2/search/web');
      expect(captured!.uri.queryParameters['sort'], 'recency');
      expect(captured!.uri.queryParameters['size'], '10');
    });

    test('uses blog recency search for regional discovery', () async {
      SearchHttpRequest? captured;
      final loader = _loader((request) async {
        captured = request;
        return _emptyResponse();
      });

      await loader.load(_query('region-weekly', DailyQueryIntents.region));

      expect(captured!.uri.path, '/v2/search/blog');
      expect(captured!.uri.queryParameters['sort'], 'recency');
    });

    test('uses blog accuracy search for culture and audience material', () {
      expect(
        DaumSearchDocumentLoader.endpointFor(
          _query('culture-weekly', DailyQueryIntents.culture),
        ),
        DaumSearchEndpoint.blog,
      );
      expect(
        DaumSearchDocumentLoader.sortFor(
          _query('audience-30s', DailyQueryIntents.audience),
        ),
        'accuracy',
      );
    });

    test('propagates sanitized provider failures to the runner boundary', () async {
      const secret = 'fixture-live-key';
      final loader = DaumSearchDocumentLoader(
        client: DaumSearchClient(
          restApiKey: secret,
          transport: (_) async => const SearchHttpResponse(
            statusCode: 429,
            body: '{"secret":"must-not-escape"}',
          ),
        ),
      );

      Object? captured;
      try {
        await loader.load(_query('nature-daily', DailyQueryIntents.nature));
      } catch (error) {
        captured = error;
      }

      expect(captured, isA<DaumSearchException>());
      expect(captured.toString(), contains('429'));
      expect(captured.toString(), isNot(contains(secret)));
      expect(captured.toString(), isNot(contains('must-not-escape')));
    });
  });

  group('DartIoSearchHttpTransport', () {
    test('rejects non-HTTPS and non-allowlisted targets before networking', () async {
      final transport = DartIoSearchHttpTransport();

      await expectLater(
        transport.call(
          SearchHttpRequest(
            uri: Uri.parse('http://dapi.kakao.com/v2/search/web'),
            headers: const {},
          ),
        ),
        throwsA(isA<SearchTransportException>()),
      );
      await expectLater(
        transport.call(
          SearchHttpRequest(
            uri: Uri.parse('https://example.com/v2/search/web'),
            headers: const {},
          ),
        ),
        throwsA(isA<SearchTransportException>()),
      );
    });

    test('validates timeout, body limit, and host allowlist configuration', () {
      expect(
        () => DartIoSearchHttpTransport(timeout: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => DartIoSearchHttpTransport(maximumResponseBytes: 0),
        throwsArgumentError,
      );
      expect(
        () => DartIoSearchHttpTransport(allowedHosts: const {}),
        throwsArgumentError,
      );
    });
  });
}

DaumSearchDocumentLoader _loader(SearchHttpTransport transport) {
  return DaumSearchDocumentLoader(
    client: DaumSearchClient(
      restApiKey: 'fixture-live-key',
      transport: transport,
    ),
  );
}

SearchHttpResponse _emptyResponse() {
  return const SearchHttpResponse(
    statusCode: 200,
    body: '{"meta":{"total_count":0,"pageable_count":0,'
        '"is_end":true},"documents":[]}',
  );
}

DailySearchQuery _query(String id, String intent) {
  return DailySearchQuery(
    id: id,
    text: '오늘 안전한 생활 자료',
    intent: intent,
    priority: 90,
    freshnessWindowDays: 7,
  );
}
