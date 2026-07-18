import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_opening_context_provider_factory.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_opening_keyword_selector.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  final date = DateTime.utc(2026, 1, 10);

  test('local factory projects a local weather signal for the opening', () async {
    final provider = DailyOpeningContextProviderFactory.local();
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
      weatherSignals: const ['비'],
    );

    final opening = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(opening, isNotNull);
    expect(opening!.selectedCandidate.keyword, '비');
    expect(opening.isConsumed, isFalse);
  });

  test('local factory does not load a projection outside the opening turn', () async {
    final provider = DailyOpeningContextProviderFactory.local();
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
      weatherSignals: const ['비'],
    );

    final opening = await provider.load(
      request: request,
      isOpeningTurn: false,
      seed: 0,
    );

    expect(opening, isNull);
  });

  test('fromSource preserves the injected source request and result', () async {
    final context = _context(date, keyword: '독서');
    final source = _FakeSource(contextToReturn: context);
    final provider = DailyOpeningContextProviderFactory.fromSource(
      source: source,
    );
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
    );

    final opening = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(source.callCount, 1);
    expect(source.receivedRequest, same(request));
    expect(opening?.selectedCandidate.keyword, '독서');
  });

  test('withFallback uses fallback after primary failure', () async {
    final primary = _FakeSource(error: StateError('primary failed'));
    final fallback = _FakeSource(
      contextToReturn: _context(date, keyword: '재활용'),
    );
    final provider = DailyOpeningContextProviderFactory.withFallback(
      primary: primary,
      fallback: fallback,
    );
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
    );

    final opening = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(primary.callCount, 1);
    expect(fallback.callCount, 1);
    expect(opening?.selectedCandidate.keyword, '재활용');
  });

  test('withFallback keeps a valid primary result without fallback call', () async {
    final primary = _FakeSource(
      contextToReturn: _context(date, keyword: '비'),
    );
    final fallback = _FakeSource(
      contextToReturn: _context(date, keyword: '독서'),
    );
    final provider = DailyOpeningContextProviderFactory.withFallback(
      primary: primary,
      fallback: fallback,
    );
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
    );

    final opening = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(primary.callCount, 1);
    expect(fallback.callCount, 0);
    expect(opening?.selectedCandidate.keyword, '비');
  });

  test('factory passes a configured selector to the provider', () async {
    final source = _FakeSource(
      contextToReturn: DailyKeywordContext(
        date: date,
        locale: 'ko-KR',
        keywords: const [
          DailyKeywordEntry(
            type: 'safe_issue',
            keyword: '독서',
            hint: '책을 천천히 읽는 이야기',
            plantHint: '조용한 시간을 함께 보내기',
            tone: 'calm',
            fitScore: 0.70,
          ),
        ],
      ),
    );
    final provider = DailyOpeningContextProviderFactory.fromSource(
      source: source,
      selector: const DailyOpeningKeywordSelector(minimumFitScore: 0.80),
    );
    final request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
    );

    final opening = await provider.load(
      request: request,
      isOpeningTurn: true,
      seed: 0,
    );

    expect(opening, isNull);
  });
}

DailyKeywordContext _context(DateTime date, {required String keyword}) {
  return DailyKeywordContext(
    date: date,
    locale: 'ko-KR',
    sourceVersion: 'test-v1',
    keywords: [
      DailyKeywordEntry(
        type: keyword == '비' ? 'weather' : 'safe_issue',
        keyword: keyword,
        hint: '안전한 오늘의 이야기',
        plantHint: '식물과 가볍게 연결하기',
        tone: 'gentle',
        fitScore: 0.80,
      ),
    ],
  );
}

class _FakeSource extends DailyKeywordSource {
  _FakeSource({this.contextToReturn, this.error});

  final DailyKeywordContext? contextToReturn;
  final Object? error;
  int callCount = 0;
  DailyKeywordSourceRequest? receivedRequest;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) {
    callCount++;
    receivedRequest = request;
    final currentError = error;
    if (currentError != null) {
      return Future<DailyKeywordContext>.error(currentError);
    }
    return Future<DailyKeywordContext>.value(contextToReturn!);
  }
}
