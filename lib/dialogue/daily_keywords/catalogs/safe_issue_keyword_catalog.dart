import '../models/daily_keyword_candidate.dart';

class SafeIssueKeywordCatalog {
  SafeIssueKeywordCatalog._();

  static const entries = <DailyKeywordCandidate>[
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '반려식물',
      hint: '반려식물을 가볍게 돌보는 이야기',
      plantHint: '새 잎과 흙 상태를 천천히 살피기',
      tone: DailyKeywordTones.gentle,
      fitScore: 0.84,
      category: 'plant_lifestyle',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '공원 산책',
      hint: '가까운 공원을 가볍게 걷는 이야기',
      plantHint: '바깥 초록을 함께 떠올리기',
      tone: DailyKeywordTones.bright,
      fitScore: 0.72,
      category: 'light_lifestyle',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '독서',
      hint: '책 한 권을 천천히 읽는 이야기',
      plantHint: '조용한 시간을 함께 보내기',
      tone: DailyKeywordTones.calm,
      fitScore: 0.68,
      category: 'light_lifestyle',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '전시회',
      hint: '가볍게 둘러볼 수 있는 전시 이야기',
      plantHint: '새로운 색과 모양을 함께 떠올리기',
      tone: DailyKeywordTones.bright,
      fitScore: 0.67,
      category: 'culture',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '분리배출',
      hint: '생활 속 분리배출을 실천하는 이야기',
      plantHint: '주변을 가볍게 정돈하기',
      tone: DailyKeywordTones.gentle,
      fitScore: 0.74,
      category: 'environmental_habit',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '재활용',
      hint: '생활 속 재활용을 돌아보는 이야기',
      plantHint: '오래 쓰는 물건을 함께 떠올리기',
      tone: DailyKeywordTones.gentle,
      fitScore: 0.70,
      category: 'environmental_habit',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '제로웨이스트',
      hint: '쓰레기를 줄이는 가벼운 생활 이야기',
      plantHint: '필요한 것만 천천히 고르기',
      tone: DailyKeywordTones.gentle,
      fitScore: 0.69,
      category: 'environmental_habit',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.safeIssue,
      keyword: '플로깅',
      hint: '산책하며 주변을 정돈하는 이야기',
      plantHint: '깨끗한 바깥 공기를 함께 떠올리기',
      tone: DailyKeywordTones.bright,
      fitScore: 0.71,
      category: 'environmental_habit',
    ),
  ];

  static List<DailyKeywordCandidate> candidatesFor(
    Iterable<String> issueSignals,
  ) {
    final entriesByKeyword = {
      for (final entry in entries) _normalize(entry.keyword): entry,
    };
    final seenSignals = <String>{};
    final candidates = <DailyKeywordCandidate>[];

    for (final signal in issueSignals) {
      final normalized = _normalize(signal);
      if (normalized.isEmpty || !seenSignals.add(normalized)) {
        continue;
      }

      final candidate = entriesByKeyword[normalized];
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    return candidates;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
