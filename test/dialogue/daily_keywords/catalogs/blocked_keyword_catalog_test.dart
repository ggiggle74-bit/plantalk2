import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/catalogs/blocked_keyword_catalog.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';

void main() {
  test(
    'blocks politics, elections, crime, violence, war, and death accidents',
    () {
      for (final keyword in <String>[
        '정치 뉴스',
        'ELECTION update',
        '살인 사건',
        'violent assault',
        '전쟁 소식',
        'fatal accident',
        'sensational crime',
      ]) {
        expect(
          BlockedKeywordCatalog.blocks(_candidate(keyword: keyword)),
          isTrue,
        );
      }
    },
  );

  test('checks hint, plant hint, and category text', () {
    expect(
      BlockedKeywordCatalog.blocks(_candidate(hint: 'war coverage')),
      isTrue,
    );
    expect(
      BlockedKeywordCatalog.blocks(_candidate(plantHint: '선거를 언급하기')),
      isTrue,
    );
    expect(
      BlockedKeywordCatalog.blocks(_candidate(category: 'violent_crime')),
      isTrue,
    );
  });

  test('allows normal weather, seasonal, and plant-safe context', () {
    expect(BlockedKeywordCatalog.blocks(_candidate(keyword: '장맛비')), isFalse);
    expect(BlockedKeywordCatalog.blocks(_candidate(keyword: '봄')), isFalse);
    expect(
      BlockedKeywordCatalog.blocks(_candidate(plantHint: '창가 빛 변화를 살피기')),
      isFalse,
    );
  });

  test('does not block safe English words containing blocked terms', () {
    for (final phrase in <String>[
      'warm sunlight',
      'warm weather',
      'grape vine',
      'grape leaves',
    ]) {
      expect(
        BlockedKeywordCatalog.blocks(_candidate(keyword: phrase)),
        isFalse,
      );
    }
  });

  test('matches English blocked terms at token and phrase boundaries', () {
    for (final phrase in <String>[
      'war',
      'war update',
      'WAR news',
      'armed war',
      'rape',
      'rape investigation',
    ]) {
      expect(BlockedKeywordCatalog.blocks(_candidate(keyword: phrase)), isTrue);
    }
    expect(
      BlockedKeywordCatalog.blocks(_candidate(category: 'violent_crime')),
      isTrue,
    );
  });
}

DailyKeywordCandidate _candidate({
  String keyword = '비',
  String hint = '비가 내리는 날',
  String plantHint = '창가 빛 변화를 살피기',
  String? category = 'rain',
}) {
  return DailyKeywordCandidate(
    type: DailyKeywordTypes.weather,
    keyword: keyword,
    hint: hint,
    plantHint: plantHint,
    tone: DailyKeywordTones.gentle,
    fitScore: 0.75,
    category: category,
  );
}
