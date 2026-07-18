import '../models/daily_keyword_candidate.dart';
import 'daily_candidate_source.dart';

final class LocalCalendarSeasonSource implements DailyCandidateSource {
  const LocalCalendarSeasonSource();

  @override
  String get id => 'local-calendar-season';

  @override
  Future<List<DailyKeywordCandidate>> load(
    DailyCandidateSourceRequest request,
  ) async {
    if (!request.locale.toLowerCase().startsWith('ko')) {
      return const [];
    }

    final candidates = <DailyKeywordCandidate>[];
    final commemorative = _commemorativeCandidate(request.date);
    if (commemorative != null) {
      candidates.add(commemorative);
    }
    candidates.add(_seasonCandidate(request.date.month));
    return List.unmodifiable(candidates);
  }

  DailyKeywordCandidate? _commemorativeCandidate(DateTime date) {
    return switch (date.month * 100 + date.day) {
      405 => _candidate(
        type: DailyKeywordTypes.calendar,
        keyword: '식목일',
        hint: '나무를 떠올리는 날',
        plantHint: '초록을 가볍게 바라보기',
        tone: DailyKeywordTones.bright,
        fitScore: 0.80,
        category: 'fixed_commemorative_day',
      ),
      505 => _candidate(
        type: DailyKeywordTypes.calendar,
        keyword: '어린이날',
        hint: '가벼운 기념일 분위기',
        plantHint: '밝은 하루를 함께 떠올리기',
        tone: DailyKeywordTones.bright,
        fitScore: 0.70,
        category: 'fixed_commemorative_day',
      ),
      515 => _candidate(
        type: DailyKeywordTypes.calendar,
        keyword: '스승의날',
        hint: '고마움을 떠올리는 날',
        plantHint: '차분한 마음을 나누기',
        tone: DailyKeywordTones.gentle,
        fitScore: 0.70,
        category: 'fixed_commemorative_day',
      ),
      _ => null,
    };
  }

  DailyKeywordCandidate _seasonCandidate(int month) {
    return switch (month) {
      3 || 4 || 5 => _candidate(
        type: DailyKeywordTypes.seasonal,
        keyword: '봄',
        hint: '봄기운이 느껴지는 때',
        plantHint: '새 잎을 가볍게 바라보기',
        tone: DailyKeywordTones.bright,
        fitScore: 0.70,
        category: 'season',
      ),
      6 || 7 || 8 => _candidate(
        type: DailyKeywordTypes.seasonal,
        keyword: '여름',
        hint: '여름 기운이 이어지는 때',
        plantHint: '한낮 빛을 의식하기',
        tone: DailyKeywordTones.bright,
        fitScore: 0.70,
        category: 'season',
      ),
      9 || 10 || 11 => _candidate(
        type: DailyKeywordTypes.seasonal,
        keyword: '가을',
        hint: '가을 공기가 느껴지는 때',
        plantHint: '차분한 빛을 바라보기',
        tone: DailyKeywordTones.calm,
        fitScore: 0.70,
        category: 'season',
      ),
      _ => _candidate(
        type: DailyKeywordTypes.seasonal,
        keyword: '겨울',
        hint: '겨울 기운이 머무는 때',
        plantHint: '창가 온도를 의식하기',
        tone: DailyKeywordTones.calm,
        fitScore: 0.70,
        category: 'season',
      ),
    };
  }

  DailyKeywordCandidate _candidate({
    required String type,
    required String keyword,
    required String hint,
    required String plantHint,
    required String tone,
    required double fitScore,
    required String category,
  }) {
    return DailyKeywordCandidate(
      type: type,
      keyword: keyword,
      hint: hint,
      plantHint: plantHint,
      tone: tone,
      fitScore: fitScore,
      relevanceScore: fitScore,
      category: category,
      conversationAngles: [
        '$keyword을 중심으로 오늘의 분위기 살피기',
        plantHint,
      ],
    );
  }
}
