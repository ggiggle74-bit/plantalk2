import '../models/daily_keyword_candidate.dart';

class SeasonalKeywordCatalog {
  SeasonalKeywordCatalog._();

  static const _spring = DailyKeywordCandidate(
    type: DailyKeywordTypes.seasonal,
    keyword: '봄',
    hint: '봄기운이 느껴지는 때',
    plantHint: '새 잎을 가볍게 바라보기',
    tone: DailyKeywordTones.bright,
    fitScore: 0.70,
    category: 'season',
  );
  static const _summer = DailyKeywordCandidate(
    type: DailyKeywordTypes.seasonal,
    keyword: '여름',
    hint: '여름 기운이 이어지는 때',
    plantHint: '한낮 빛을 의식하기',
    tone: DailyKeywordTones.bright,
    fitScore: 0.70,
    category: 'season',
  );
  static const _autumn = DailyKeywordCandidate(
    type: DailyKeywordTypes.seasonal,
    keyword: '가을',
    hint: '가을 공기가 느껴지는 때',
    plantHint: '차분한 빛을 바라보기',
    tone: DailyKeywordTones.calm,
    fitScore: 0.70,
    category: 'season',
  );
  static const _winter = DailyKeywordCandidate(
    type: DailyKeywordTypes.seasonal,
    keyword: '겨울',
    hint: '겨울 기운이 머무는 때',
    plantHint: '창가 온도를 의식하기',
    tone: DailyKeywordTones.calm,
    fitScore: 0.70,
    category: 'season',
  );

  static List<DailyKeywordCandidate> candidatesFor({
    required DateTime date,
    required String locale,
  }) {
    if (!locale.trim().toLowerCase().startsWith('ko')) {
      return const [];
    }

    final candidate = switch (date.month) {
      3 || 4 || 5 => _spring,
      6 || 7 || 8 => _summer,
      9 || 10 || 11 => _autumn,
      _ => _winter,
    };
    return [candidate];
  }
}
