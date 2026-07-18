import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_opening_context_provider.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  final today = DateTime.utc(2026, 7, 18);
  final request = DailyKeywordSourceRequest(
    date: today,
    locale: 'ko-KR',
    weatherSignals: const ['비'],
  );

  test('does not call the source outside the opening turn', () async {
    final source = _FakeDailyKeywordSource(_context(today));
    final provider = DailyOpeningContextProvider(source: source);

    final openingContext = await provider.load(
      request: request,
      isOpeningTurn: false,
      seed: 0,
    );

    expect(openingContext, isNull);
    expect(source.callCount, 0);
  });

  test('projects one unconsumed opening context from a valid source', () async {
    final source = _FakeDailyKeywordSource(_context(today));
    final provider = DailyOpeningContextProvider(source: source);

    final openingContext = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(source.callCount, 1);
    expect(source.requests.single, same(request));
    expect(openingContext, isNotNull);
    expect(openingContext!.selectedCandidate.keyword, '비');
    expect(openingContext.isConsumed, isFalse);
  });

  test('returns null for an empty source context', () async {
    final source = _FakeDailyKeywordSource(
      DailyKeywordContext(
        date: today,
        locale: 'ko-KR',
        keywords: const [],
      ),
    );
    final provider = DailyOpeningContextProvider(source: source);

    final openingContext = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(openingContext, isNull);
  });

  test('returns null when the source context date is stale', () async {
    final source = _FakeDailyKeywordSource(
      _context(today.subtract(const Duration(days: 1))),
    );
    final provider = DailyOpeningContextProvider(source: source);

    final openingContext = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(openingContext, isNull);
  });

  test('returns null when the source fails', () async {
    final source = _ThrowingDailyKeywordSource();
    final provider = DailyOpeningContextProvider(source: source);

    final openingContext = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(openingContext, isNull);
    expect(source.callCount, 1);
  });
}

DailyKeywordContext _context(DateTime date) {
  return DailyKeywordContext(
    date: date,
    locale: 'ko-KR',
    sourceVersion: 'test-source-v1',
    keywords: const [
      DailyKeywordEntry(
        type: 'weather',
        keyword: '비',
        hint: '비가 내리는 날',
        plantHint: '창가 빛 변화를 살피기',
        tone: 'gentle',
        fitScore: 0.82,
      ),
    ],
  );
}

class _FakeDailyKeywordSource implements DailyKeywordSource {
  _FakeDailyKeywordSource(this.context);

  final DailyKeywordContext context;
  final List<DailyKeywordSourceRequest> requests = [];

  int get callCount => requests.length;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) async {
    requests.add(request);
    return context;
  }
}

class _ThrowingDailyKeywordSource implements DailyKeywordSource {
  int callCount = 0;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) async {
    callCount++;
    throw StateError('source failed');
  }
}
