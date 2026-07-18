import 'dart:convert';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  const validator = DailyKeywordContractValidator();

  test('round-trips a valid app-facing daily keyword document', () {
    final document = DailyKeywordContextDocument(
      date: DateTime.utc(2026, 7, 18),
      locale: 'ko-KR',
      regionCode: 'global',
      generatedAt: DateTime.utc(2026, 7, 18, 5, 30),
      sourceVersion: 'collector-contract-v1',
      keywords: [
        _candidate(
          type: DailyKeywordTypes.weather,
          keyword: '장맛비',
          category: 'rain',
          relevanceScore: 0.92,
          targetAgeBands: const [
            DailyKeywordAgeBands.teens,
            DailyKeywordAgeBands.twenties,
          ],
          conversationAngles: const [
            '비 오는 날의 기분',
            '창밖 풍경',
            '화분의 과습 걱정',
          ],
        ),
      ],
    );

    final validation = validator.validate(document);
    final json = document.toJson();
    final decoded = DailyKeywordContextDocument.decode(document.encode());

    expect(validation.isValid, isTrue);
    expect(json.keys, [
      'schemaVersion',
      'date',
      'locale',
      'regionCode',
      'generatedAt',
      'sourceVersion',
      'keywords',
    ]);
    expect(json['date'], '2026-07-18');
    expect(json['schemaVersion'], 'daily-keyword-context/v1');
    expect(decoded.locale, 'ko-KR');
    expect(decoded.regionCode, 'global');
    expect(decoded.keywords.single.keyword, '장맛비');
    expect(decoded.keywords.single.plantHint, '화분 상태를 천천히 살피기');
    expect(decoded.keywords.single.conversationAngles, hasLength(3));
    expect(decoded.keywords.single.targetAgeBands, ['10s', '20s']);
  });

  test('normalizes candidate values and document timestamps', () {
    final document = DailyKeywordContextDocument(
      date: DateTime(2026, 7, 18, 15),
      locale: ' ko-KR ',
      regionCode: ' global ',
      generatedAt: DateTime.parse('2026-07-18T14:30:00+09:00'),
      sourceVersion: ' collector-v1 ',
      keywords: [
        DailyKeywordCandidate(
          type: ' WEATHER ',
          keyword: '  비  ',
          hint: '  비가 이어지는 날  ',
          plantHint: '  창가 빛을 살피기  ',
          tone: ' GENTLE ',
          fitScore: 0.80,
          conversationAngles: const ['  빗소리 듣기  '],
          targetAgeBands: const [' 20S ', ' 30s '],
        ),
      ],
    );

    expect(document.date, DateTime.utc(2026, 7, 18));
    expect(document.locale, 'ko-KR');
    expect(document.regionCode, 'global');
    expect(document.generatedAt, DateTime.utc(2026, 7, 18, 5, 30));
    expect(document.sourceVersion, 'collector-v1');
    expect(document.keywords.single.type, DailyKeywordTypes.weather);
    expect(document.keywords.single.keyword, '비');
    expect(document.keywords.single.tone, DailyKeywordTones.gentle);
    expect(document.keywords.single.conversationAngles, ['빗소리 듣기']);
    expect(document.keywords.single.targetAgeBands, ['20s', '30s']);
    expect(validator.validate(document).isValid, isTrue);
  });

  test('omits targetAgeBands when a candidate is universal', () {
    final candidate = _candidate(
      type: DailyKeywordTypes.seasonal,
      keyword: '한여름',
      conversationAngles: const ['여름 햇빛'],
    );

    final json = candidate.toJson();
    final decoded = DailyKeywordCandidate.fromJson(json);

    expect(candidate.targetAgeBands, isEmpty);
    expect(json.containsKey('targetAgeBands'), isFalse);
    expect(decoded.targetAgeBands, isEmpty);
  });

  test('rejects unsupported values, low scores, and missing angles', () {
    final document = DailyKeywordContextDocument(
      date: DateTime.utc(2026, 7, 18),
      locale: 'ko-KR',
      regionCode: 'global',
      generatedAt: DateTime.utc(2026, 7, 18),
      sourceVersion: 'collector-v1',
      keywords: [
        DailyKeywordCandidate(
          type: 'finance',
          keyword: '환율',
          hint: '금융 시장 이야기',
          plantHint: '식물과 연결되지 않음',
          tone: 'dramatic',
          fitScore: 0.59,
          relevanceScore: 1.2,
          conversationAngles: const [],
          targetAgeBands: const ['children', '20s', ' 20S '],
        ),
      ],
    );

    final result = validator.validate(document);

    expect(result.isValid, isFalse);
    expect(result.errors, anyElement(contains('type is not supported')));
    expect(result.errors, anyElement(contains('tone is not supported')));
    expect(result.errors, anyElement(contains('fitScore')));
    expect(result.errors, anyElement(contains('relevanceScore')));
    expect(result.errors, anyElement(contains('must not be empty')));
    expect(result.errors, anyElement(contains('targetAgeBands')));
    expect(result.errors, anyElement(contains('duplicates an earlier age band')));
    expect(() => result.throwIfInvalid(), throwsFormatException);
  });

  test('rejects duplicate candidates and duplicate conversation angles', () {
    final document = DailyKeywordContextDocument(
      date: DateTime.utc(2026, 7, 18),
      locale: 'ko-KR',
      regionCode: 'global',
      generatedAt: DateTime.utc(2026, 7, 18),
      sourceVersion: 'collector-v1',
      keywords: [
        _candidate(
          type: DailyKeywordTypes.safeIssue,
          keyword: '플로깅',
          conversationAngles: const ['공원 산책', ' 공원   산책 '],
        ),
        _candidate(
          type: ' SAFE_ISSUE ',
          keyword: ' 플로깅 ',
          conversationAngles: const ['환경 활동'],
        ),
      ],
    );

    final result = validator.validate(document);

    expect(result.isValid, isFalse);
    expect(result.errors, anyElement(contains('duplicates an earlier angle')));
    expect(
      result.errors,
      anyElement(contains('duplicates an earlier type and keyword')),
    );
  });

  test('limits a ready-to-store document to eight candidates', () {
    final document = DailyKeywordContextDocument(
      date: DateTime.utc(2026, 7, 18),
      locale: 'ko-KR',
      regionCode: 'global',
      generatedAt: DateTime.utc(2026, 7, 18),
      sourceVersion: 'collector-v1',
      keywords: List.generate(
        9,
        (index) => _candidate(
          type: DailyKeywordTypes.safeIssue,
          keyword: '안전 소재 $index',
          conversationAngles: ['대화 관점 $index'],
        ),
      ),
    );

    final result = validator.validate(document);

    expect(result.isValid, isFalse);
    expect(result.errors, contains('keywords must contain at most 8 candidates.'));
  });

  test('allows an empty document as a terminal collector result', () {
    final document = DailyKeywordContextDocument(
      date: DateTime.utc(2026, 7, 18),
      locale: 'ko-KR',
      regionCode: 'global',
      generatedAt: DateTime.utc(2026, 7, 18),
      sourceVersion: 'collector-v1',
      keywords: const [],
    );

    expect(validator.validate(document).isValid, isTrue);
    expect(document.toJson()['keywords'], isEmpty);
  });

  test('decode rejects unsupported schema versions and invalid dates', () {
    final validJson = <String, Object?>{
      'schemaVersion': DailyKeywordContextDocument.currentSchemaVersion,
      'date': '2026-07-18',
      'locale': 'ko-KR',
      'regionCode': 'global',
      'generatedAt': '2026-07-18T05:30:00.000Z',
      'sourceVersion': 'collector-v1',
      'keywords': <Object?>[],
    };

    final wrongSchema = Map<String, Object?>.from(validJson)
      ..['schemaVersion'] = 'daily-keyword-context/v2';
    final invalidDate = Map<String, Object?>.from(validJson)
      ..['date'] = '2026-02-30';

    expect(
      () => DailyKeywordContextDocument.decode(jsonEncode(wrongSchema)),
      throwsFormatException,
    );
    expect(
      () => DailyKeywordContextDocument.decode(jsonEncode(invalidDate)),
      throwsFormatException,
    );
  });
}

DailyKeywordCandidate _candidate({
  required String type,
  required String keyword,
  required Iterable<String> conversationAngles,
  String? category,
  double? relevanceScore,
  Iterable<String> targetAgeBands = const [],
}) {
  return DailyKeywordCandidate(
    type: type,
    keyword: keyword,
    hint: '오늘 가볍게 나눌 수 있는 이야기',
    category: category,
    relevanceScore: relevanceScore,
    plantHint: '화분 상태를 천천히 살피기',
    tone: DailyKeywordTones.gentle,
    fitScore: 0.80,
    conversationAngles: conversationAngles,
    targetAgeBands: targetAgeBands,
  );
}
