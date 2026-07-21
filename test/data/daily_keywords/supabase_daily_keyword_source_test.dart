import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/data/daily_keywords/supabase_daily_keyword_source.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_source_request.dart';

void main() {
  final date = DateTime(2026, 7, 21, 13);
  late DailyKeywordSourceRequest request;

  setUp(() {
    request = DailyKeywordSourceRequest(
      date: date,
      locale: 'ko-KR',
      regionCode: 'global',
    );
  });

  test('loads an exact context row and maps the collector contract', () async {
    String? receivedDate;
    String? receivedLocale;
    String? receivedRegion;
    final source = SupabaseDailyKeywordSource(
      fetchRow:
          ({
            required contextDate,
            required locale,
            required regionCode,
          }) async {
            receivedDate = contextDate;
            receivedLocale = locale;
            receivedRegion = regionCode;
            return _row();
          },
    );

    final context = await source.load(request);

    expect(receivedDate, '2026-07-21');
    expect(receivedLocale, 'ko-KR');
    expect(receivedRegion, 'global');
    expect(context.date, DateTime(2026, 7, 21));
    expect(context.locale, 'ko-KR');
    expect(context.sourceVersion, 'collector-cr2i');
    expect(context.generatedAt, DateTime.utc(2026, 7, 21, 1, 17));
    expect(context.keywords, hasLength(1));

    final keyword = context.keywords.single;
    expect(keyword.type, 'weather');
    expect(keyword.keyword, '장맛비');
    expect(keyword.category, 'rain');
    expect(keyword.relevanceScore, 0.91);
    expect(keyword.plantHint, '창가의 빗물을 피하기');
    expect(keyword.tone, 'gentle');
    expect(keyword.fitScore, 0.82);
    expect(keyword.targetAgeBands, ['20s']);
  });

  test('returns an empty context when the exact row is absent', () async {
    final source = SupabaseDailyKeywordSource(
      fetchRow:
          ({
            required contextDate,
            required locale,
            required regionCode,
          }) async => null,
    );

    final context = await source.load(request);

    expect(context.date, same(date));
    expect(context.locale, 'ko-KR');
    expect(context.keywords, isEmpty);
    expect(context.generatedAt, isNull);
    expect(context.sourceVersion, isNull);
  });

  test('rejects a row outside the requested region', () {
    final source = SupabaseDailyKeywordSource(
      fetchRow:
          ({
            required contextDate,
            required locale,
            required regionCode,
          }) async => _row(regionCode: 'KR-11'),
    );

    expect(source.load(request), throwsA(isA<FormatException>()));
  });

  test('keeps safe valid candidates and drops unsafe or malformed ones', () async {
    final source = SupabaseDailyKeywordSource(
      fetchRow:
          ({
            required contextDate,
            required locale,
            required regionCode,
          }) async {
            return _row(
              keywords: [
                _keyword(),
                _keyword(keyword: '전쟁', hint: '차단되어야 하는 이야기'),
                {
                  'type': 'weather',
                  'keyword': '비',
                  'hint': '대화 각도가 빠진 항목',
                  'plantHint': '잎을 살피기',
                  'tone': 'gentle',
                  'fitScore': 0.8,
                },
              ],
            );
          },
    );

    final context = await source.load(request);

    expect(context.keywords.map((entry) => entry.keyword), ['장맛비']);
  });

  test('rejects an oversized remote keyword collection', () {
    final source = SupabaseDailyKeywordSource(
      fetchRow:
          ({
            required contextDate,
            required locale,
            required regionCode,
          }) async {
            return _row(
              keywords: List.generate(9, (_) => _keyword()),
            );
          },
    );

    expect(source.load(request), throwsA(isA<FormatException>()));
  });

  test('times out a stalled remote row request', () {
    final completer = Completer<Map<String, dynamic>?>();
    final source = SupabaseDailyKeywordSource(
      timeout: const Duration(milliseconds: 1),
      fetchRow:
          ({
            required contextDate,
            required locale,
            required regionCode,
          }) => completer.future,
    );

    expect(source.load(request), throwsA(isA<TimeoutException>()));
  });

  test('requires a positive timeout', () {
    expect(
      () => SupabaseDailyKeywordSource(
        timeout: Duration.zero,
        fetchRow:
            ({
              required contextDate,
              required locale,
              required regionCode,
            }) async => null,
      ),
      throwsArgumentError,
    );
  });
}

Map<String, dynamic> _row({
  String regionCode = 'global',
  List<Map<String, dynamic>>? keywords,
}) {
  return {
    'context_date': '2026-07-21',
    'locale': 'ko-KR',
    'region_code': regionCode,
    'schema_version': 'daily-keyword-context/v1',
    'generated_at': '2026-07-21T01:17:00Z',
    'source_version': 'collector-cr2i',
    'keywords': keywords ?? [_keyword()],
  };
}

Map<String, dynamic> _keyword({
  String keyword = '장맛비',
  String hint = '비가 이어지는 날',
}) {
  return {
    'type': 'weather',
    'keyword': keyword,
    'hint': hint,
    'category': 'rain',
    'relevanceScore': 0.91,
    'plantHint': '창가의 빗물을 피하기',
    'tone': 'gentle',
    'fitScore': 0.82,
    'conversationAngles': ['빗소리를 중심으로 가볍게 이야기하기'],
    'targetAgeBands': ['20s'],
  };
}
