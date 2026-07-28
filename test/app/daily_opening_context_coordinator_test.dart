import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/app/daily_opening_context_coordinator.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_opening_context_provider_factory.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  final date = DateTime(2026, 7, 21, 13);

  test('loads one opening context with the requested region scope', () async {
    final source = _RecordingSource(
      context: _context(date, keywords: const ['장맛비']),
    );
    final coordinator = DailyOpeningContextCoordinator(
      provider: DailyOpeningContextProviderFactory.fromSource(source: source),
    );

    final opening = await coordinator.loadForChat(
      date: date,
      locale: 'ko-KR',
      regionCode: 'KR-49',
      plantKey: 'plant-1',
      weatherSignals: const ['비'],
    );

    expect(opening?.selectedCandidate.keyword, '장맛비');
    expect(opening?.isConsumed, isFalse);
    expect(source.request?.date, same(date));
    expect(source.request?.locale, 'ko-KR');
    expect(source.request?.regionCode, 'KR-49');
    expect(source.request?.weatherSignals, ['비']);
  });

  test('uses fallback source after a remote source failure', () async {
    final coordinator = DailyOpeningContextCoordinator(
      provider: DailyOpeningContextProviderFactory.withFallback(
        primary: _RecordingSource(error: StateError('remote failed')),
        fallback: _RecordingSource(
          context: _context(date, keywords: const ['여름']),
        ),
      ),
    );

    final opening = await coordinator.loadForChat(
      date: date,
      locale: 'ko-KR',
      plantKey: 'plant-1',
    );

    expect(opening?.selectedCandidate.keyword, '여름');
  });

  test('uses fallback source when the remote context is empty', () async {
    final coordinator = DailyOpeningContextCoordinator(
      provider: DailyOpeningContextProviderFactory.withFallback(
        primary: _RecordingSource(
          context: _context(date, keywords: const []),
        ),
        fallback: _RecordingSource(
          context: _context(date, keywords: const ['독서']),
        ),
      ),
    );

    final opening = await coordinator.loadForChat(
      date: date,
      locale: 'ko-KR',
      plantKey: 'plant-1',
    );

    expect(opening?.selectedCandidate.keyword, '독서');
  });

  test('loads opening and session material from one source request', () async {
    final source = _RecordingSource(
      context: _context(date, keywords: const ['장맛비', '독서']),
    );
    final coordinator = DailyOpeningContextCoordinator.fromSource(
      source: source,
    );

    final bundle = await coordinator.loadSessionForChat(
      date: date,
      locale: 'ko-KR',
      plantKey: 'plant-1',
    );

    expect(source.callCount, 1);
    expect(bundle.openingContext, isNotNull);
    expect(
      bundle.materialContext?.materials.map((material) => material.keyword),
      ['장맛비', '독서'],
    );
  });

  test('keeps selection deterministic for the same chat identity', () async {
    final source = _RecordingSource(
      context: _context(date, keywords: const ['장맛비', '독서']),
    );
    final coordinator = DailyOpeningContextCoordinator(
      provider: DailyOpeningContextProviderFactory.fromSource(source: source),
    );

    final first = await coordinator.loadForChat(
      date: date,
      locale: 'ko-KR',
      plantKey: 'plant-1',
    );
    final second = await coordinator.loadForChat(
      date: date,
      locale: 'ko-KR',
      plantKey: 'plant-1',
    );

    expect(
      second?.selectedCandidate.keyword,
      first?.selectedCandidate.keyword,
    );
  });
}

DailyKeywordContext _context(
  DateTime date, {
  required List<String> keywords,
}) {
  return DailyKeywordContext(
    date: date,
    locale: 'ko-KR',
    sourceVersion: 'test-v1',
    keywords: keywords
        .map(
          (keyword) => DailyKeywordEntry(
            type: keyword == '장맛비' ? 'weather' : 'safe_issue',
            keyword: keyword,
            hint: '안전한 오늘의 이야기',
            plantHint: '식물과 가볍게 연결하기',
            tone: 'gentle',
            fitScore: 0.8,
          ),
        )
        .toList(),
  );
}

class _RecordingSource implements DailyKeywordSource {
  _RecordingSource({this.context, this.error});

  final DailyKeywordContext? context;
  final Object? error;
  DailyKeywordSourceRequest? request;
  int callCount = 0;

  @override
  Future<DailyKeywordContext> load(DailyKeywordSourceRequest request) async {
    callCount++;
    this.request = request;
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }
    return context!;
  }
}
