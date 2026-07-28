import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_conversation_material_provider.dart';
import 'package:plantalk2/dialogue/daily_keywords/daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  final request = DailyKeywordSourceRequest(
    date: DateTime.utc(2026, 7, 28),
    locale: 'ko-KR',
    regionCode: 'global',
  );

  test('loads and projects one source context exactly once', () async {
    final source = _RecordingSource(
      context: _context(request.date),
    );
    final provider = DailyConversationMaterialProvider(source: source);

    final result = await provider.load(request: request);

    expect(source.callCount, 1);
    expect(source.request, same(request));
    expect(result?.materials.map((material) => material.keyword), ['비']);
  });

  test('returns null after a source failure', () async {
    final source = _RecordingSource(error: StateError('source failed'));
    final provider = DailyConversationMaterialProvider(source: source);

    final result = await provider.load(request: request);

    expect(result, isNull);
    expect(source.callCount, 1);
  });

  test('returns null when the source context is stale', () async {
    final source = _RecordingSource(
      context: _context(request.date.subtract(const Duration(days: 1))),
    );
    final provider = DailyConversationMaterialProvider(source: source);

    final result = await provider.load(request: request);

    expect(result, isNull);
  });
}

DailyKeywordContext _context(DateTime date) {
  return DailyKeywordContext(
    date: date,
    locale: 'ko-KR',
    sourceVersion: 'test-v1',
    keywords: const [
      DailyKeywordEntry(
        type: 'weather',
        keyword: '비',
        hint: '비가 내리는 날',
        plantHint: '창가의 빗소리를 함께 듣기',
        tone: 'gentle',
        fitScore: 0.82,
      ),
    ],
  );
}

class _RecordingSource implements DailyKeywordSource {
  _RecordingSource({this.context, this.error});

  final DailyKeywordContext? context;
  final Object? error;
  int callCount = 0;
  DailyKeywordSourceRequest? request;

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
