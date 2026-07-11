import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/fallback_daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  final request = DailyKeywordSourceRequest(
    date: DateTime.utc(2026, 7, 8),
    locale: 'ko-KR',
    weatherSignals: const ['비'],
  );

  test(
    'returns a non-empty primary context without calling fallback',
    () async {
      final primaryContext = _context(
        request,
        keyword: '비',
        sourceVersion: 'primary-v1',
      );
      final primary = _FakeDailyKeywordSource(contextToReturn: primaryContext);
      final fallback = _FakeDailyKeywordSource(
        contextToReturn: _context(
          request,
          keyword: '봄',
          sourceVersion: 'fallback-v1',
        ),
      );
      final source = FallbackDailyKeywordSource(
        primary: primary,
        fallback: fallback,
      );

      final result = await source.load(request);

      expect(result, same(primaryContext));
      expect(primary.callCount, 1);
      expect(fallback.callCount, 0);
    },
  );

  test('uses fallback once when primary returns an empty context', () async {
    final primary = _FakeDailyKeywordSource(
      contextToReturn: _emptyContext(request),
    );
    final fallbackContext = _context(
      request,
      keyword: '봄',
      sourceVersion: 'fallback-v1',
    );
    final fallback = _FakeDailyKeywordSource(contextToReturn: fallbackContext);
    final source = FallbackDailyKeywordSource(
      primary: primary,
      fallback: fallback,
    );

    final result = await source.load(request);

    expect(result, same(fallbackContext));
    expect(primary.callCount, 1);
    expect(fallback.callCount, 1);
    expect(primary.receivedRequest, same(request));
    expect(fallback.receivedRequest, same(request));
  });

  test(
    'uses fallback after synchronous or asynchronous primary failure',
    () async {
      for (final primary in [
        _FakeDailyKeywordSource(synchronousError: StateError('primary sync')),
        _FakeDailyKeywordSource(asynchronousError: StateError('primary async')),
      ]) {
        final fallbackContext = _context(
          request,
          keyword: '비',
          sourceVersion: 'fallback-v1',
        );
        final fallback = _FakeDailyKeywordSource(
          contextToReturn: fallbackContext,
        );
        final source = FallbackDailyKeywordSource(
          primary: primary,
          fallback: fallback,
        );

        final result = await source.load(request);

        expect(result, same(fallbackContext));
        expect(primary.callCount, 1);
        expect(fallback.callCount, 1);
      }
    },
  );

  test('returns an empty fallback context unchanged', () async {
    final primary = _FakeDailyKeywordSource(
      contextToReturn: _emptyContext(request),
    );
    final fallbackContext = DailyKeywordContext(
      date: request.date,
      locale: request.locale,
      generatedAt: DateTime.utc(2026, 7, 8, 3),
      sourceVersion: 'fallback-empty-v1',
      keywords: const [],
    );
    final fallback = _FakeDailyKeywordSource(contextToReturn: fallbackContext);
    final source = FallbackDailyKeywordSource(
      primary: primary,
      fallback: fallback,
    );

    final result = await source.load(request);

    expect(result, same(fallbackContext));
    expect(result.sourceVersion, 'fallback-empty-v1');
    expect(result.generatedAt, DateTime.utc(2026, 7, 8, 3));
  });

  test(
    'returns terminal empty context after synchronous fallback failure',
    () async {
      final source = FallbackDailyKeywordSource(
        primary: _FakeDailyKeywordSource(
          contextToReturn: _emptyContext(request),
        ),
        fallback: _FakeDailyKeywordSource(
          synchronousError: StateError('fallback sync'),
        ),
      );

      final result = await source.load(request);

      _expectTerminalEmpty(result, request);
    },
  );

  test(
    'returns terminal empty context after asynchronous fallback failure',
    () async {
      final source = FallbackDailyKeywordSource(
        primary: _FakeDailyKeywordSource(
          asynchronousError: StateError('primary async'),
        ),
        fallback: _FakeDailyKeywordSource(
          asynchronousError: StateError('fallback async'),
        ),
      );

      final result = await source.load(request);

      _expectTerminalEmpty(result, request);
    },
  );

  test('does not merge primary and fallback keywords', () async {
    final primary = _FakeDailyKeywordSource(
      contextToReturn: _emptyContext(request),
    );
    final fallbackContext = _context(
      request,
      keyword: '봄',
      sourceVersion: 'fallback-v1',
    );
    final source = FallbackDailyKeywordSource(
      primary: primary,
      fallback: _FakeDailyKeywordSource(contextToReturn: fallbackContext),
    );

    final result = await source.load(request);

    expect(result, same(fallbackContext));
    expect(result.keywords.map((entry) => entry.keyword), ['봄']);
  });

  test(
    'returns the same source result deterministically for the same request',
    () async {
      final primaryContext = _context(
        request,
        keyword: '비',
        sourceVersion: 'primary-v1',
      );
      final primary = _FakeDailyKeywordSource(contextToReturn: primaryContext);
      final source = FallbackDailyKeywordSource(
        primary: primary,
        fallback: _FakeDailyKeywordSource(
          contextToReturn: _emptyContext(request),
        ),
      );

      expect(await source.load(request), same(primaryContext));
      expect(await source.load(request), same(primaryContext));
      expect(primary.callCount, 2);
    },
  );
}

DailyKeywordContext _context(
  DailyKeywordSourceRequest request, {
  required String keyword,
  required String sourceVersion,
}) {
  return DailyKeywordContext(
    date: request.date,
    locale: request.locale,
    generatedAt: DateTime.utc(2026, 7, 8, 2),
    sourceVersion: sourceVersion,
    keywords: [
      DailyKeywordEntry(type: 'weather', keyword: keyword, hint: '짧은 문맥'),
    ],
  );
}

DailyKeywordContext _emptyContext(DailyKeywordSourceRequest request) {
  return DailyKeywordContext(
    date: request.date,
    locale: request.locale,
    keywords: const [],
  );
}

void _expectTerminalEmpty(
  DailyKeywordContext context,
  DailyKeywordSourceRequest request,
) {
  expect(context.date, request.date);
  expect(context.locale, request.locale);
  expect(context.keywords, isEmpty);
  expect(context.sourceVersion, isNull);
  expect(context.generatedAt, isNull);
}

class _FakeDailyKeywordSource extends DailyKeywordSource {
  _FakeDailyKeywordSource({
    this.contextToReturn,
    this.synchronousError,
    this.asynchronousError,
  });

  final DailyKeywordContext? contextToReturn;
  final Object? synchronousError;
  final Object? asynchronousError;
  int callCount = 0;
  DailyKeywordSourceRequest? receivedRequest;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) {
    callCount++;
    receivedRequest = request;
    if (synchronousError != null) {
      throw synchronousError!;
    }
    if (asynchronousError != null) {
      return Future<DailyKeywordContext>.error(asynchronousError!);
    }
    return Future<DailyKeywordContext>.value(contextToReturn!);
  }
}
