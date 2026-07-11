import '../models/daily_keyword_candidate.dart';

class CalendarKeywordCatalog {
  CalendarKeywordCatalog._();

  static const _entriesByMonthDay = <int, DailyKeywordCandidate>{
    405: DailyKeywordCandidate(
      type: DailyKeywordTypes.calendar,
      keyword: '식목일',
      hint: '나무를 떠올리는 날',
      plantHint: '초록을 가볍게 바라보기',
      tone: DailyKeywordTones.bright,
      fitScore: 0.80,
      category: 'fixed_commemorative_day',
    ),
    505: DailyKeywordCandidate(
      type: DailyKeywordTypes.calendar,
      keyword: '어린이날',
      hint: '가벼운 기념일 분위기',
      plantHint: '밝은 하루를 함께 떠올리기',
      tone: DailyKeywordTones.bright,
      fitScore: 0.70,
      category: 'fixed_commemorative_day',
    ),
    515: DailyKeywordCandidate(
      type: DailyKeywordTypes.calendar,
      keyword: '스승의날',
      hint: '고마움을 떠올리는 날',
      plantHint: '차분한 마음을 나누기',
      tone: DailyKeywordTones.gentle,
      fitScore: 0.70,
      category: 'fixed_commemorative_day',
    ),
  };

  static List<DailyKeywordCandidate> candidatesFor({
    required DateTime date,
    required String locale,
  }) {
    if (!_isKoreanLocale(locale)) {
      return const [];
    }

    final candidate = _entriesByMonthDay[date.month * 100 + date.day];
    return candidate == null ? const [] : [candidate];
  }

  static bool _isKoreanLocale(String locale) {
    return locale.trim().toLowerCase().startsWith('ko');
  }
}
