import '../models/daily_keyword_candidate.dart';
import '../models/search_document.dart';

final class DailyKeywordExtractionResult {
  DailyKeywordExtractionResult({
    required Iterable<DailyKeywordCandidate> candidates,
    required this.blockedDocumentCount,
    required this.staleDocumentCount,
    required this.unmatchedDocumentCount,
  }) : candidates = List.unmodifiable(candidates);

  final List<DailyKeywordCandidate> candidates;
  final int blockedDocumentCount;
  final int staleDocumentCount;
  final int unmatchedDocumentCount;
}

final class DailyKeywordExtractionPolicy {
  const DailyKeywordExtractionPolicy({
    this.maximumCandidates = 8,
    this.maximumPerType = 3,
    this.minimumRelevanceScore = 0.60,
  });

  final int maximumCandidates;
  final int maximumPerType;
  final double minimumRelevanceScore;

  DailyKeywordExtractionResult extract({
    required DateTime date,
    required Iterable<SearchDocument> documents,
  }) {
    if (maximumCandidates < 1 || maximumCandidates > 8) {
      throw StateError('maximumCandidates must be between 1 and 8.');
    }
    if (maximumPerType < 1 || maximumPerType > maximumCandidates) {
      throw StateError(
        'maximumPerType must be between 1 and maximumCandidates.',
      );
    }
    if (!minimumRelevanceScore.isFinite ||
        minimumRelevanceScore < 0 ||
        minimumRelevanceScore > 1) {
      throw StateError('minimumRelevanceScore must be between 0 and 1.');
    }

    final referenceEnd = DateTime.utc(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    );
    final bestByKey = <String, DailyKeywordCandidate>{};
    var blockedCount = 0;
    var staleCount = 0;
    var unmatchedCount = 0;

    for (final document in documents) {
      final searchable = _normalize('${document.title} ${document.snippet}');
      if (_containsBlockedTerm(searchable)) {
        blockedCount++;
        continue;
      }

      final freshness = _freshnessScore(document, referenceEnd);
      if (freshness == null) {
        staleCount++;
        continue;
      }

      var matched = false;
      for (final seed in _seeds) {
        if (!_containsKeyword(searchable, seed.keyword)) {
          continue;
        }
        matched = true;
        final relevance = _score(document, seed, freshness);
        if (relevance < minimumRelevanceScore) {
          continue;
        }

        final candidate = DailyKeywordCandidate(
          type: seed.type,
          keyword: seed.keyword,
          hint: seed.hint,
          plantHint: seed.plantHint,
          tone: seed.tone,
          fitScore: seed.fitScore,
          relevanceScore: relevance,
          category: seed.category,
          conversationAngles: [
            '${seed.keyword}을 중심으로 가볍게 이야기하기',
            seed.plantHint,
          ],
          targetAgeBands: document.targetAgeBands,
        );
        final key = '${seed.type}|${_normalize(seed.keyword)}';
        final existing = bestByKey[key];
        if (existing == null ||
            relevance > (existing.relevanceScore ?? 0.0)) {
          bestByKey[key] = candidate;
        }
      }
      if (!matched) {
        unmatchedCount++;
      }
    }

    final ranked = bestByKey.values.toList()
      ..sort((left, right) {
        final relevanceOrder = (right.relevanceScore ?? 0.0).compareTo(
          left.relevanceScore ?? 0.0,
        );
        if (relevanceOrder != 0) {
          return relevanceOrder;
        }
        final fitOrder = right.fitScore.compareTo(left.fitScore);
        if (fitOrder != 0) {
          return fitOrder;
        }
        return left.keyword.compareTo(right.keyword);
      });

    final selected = <DailyKeywordCandidate>[];
    final countsByType = <String, int>{};
    for (final candidate in ranked) {
      final typeCount = countsByType[candidate.type] ?? 0;
      if (typeCount >= maximumPerType) {
        continue;
      }
      selected.add(candidate);
      countsByType[candidate.type] = typeCount + 1;
      if (selected.length == maximumCandidates) {
        break;
      }
    }

    return DailyKeywordExtractionResult(
      candidates: selected,
      blockedDocumentCount: blockedCount,
      staleDocumentCount: staleCount,
      unmatchedDocumentCount: unmatchedCount,
    );
  }

  double? _freshnessScore(
    SearchDocument document,
    DateTime referenceEnd,
  ) {
    final publishedAt = document.publishedAt;
    if (publishedAt == null) {
      return 0.65;
    }
    if (publishedAt.isAfter(referenceEnd.add(const Duration(days: 1)))) {
      return null;
    }

    final ageHours = referenceEnd.difference(publishedAt).inMinutes / 60.0;
    final ageDays = ageHours < 0 ? 0.0 : ageHours / 24.0;
    if (ageDays > document.freshnessWindowDays) {
      return null;
    }
    final remaining =
        1.0 - (ageDays / document.freshnessWindowDays).clamp(0.0, 1.0);
    return 0.55 + (remaining * 0.45);
  }

  double _score(
    SearchDocument document,
    _ExtractionSeed seed,
    double freshness,
  ) {
    final priority = document.queryPriority / 100.0;
    final value =
        (seed.fitScore * 0.50) + (priority * 0.30) + (freshness * 0.20);
    return double.parse(value.clamp(0.0, 1.0).toStringAsFixed(4));
  }

  bool _containsBlockedTerm(String value) {
    for (final term in _blockedTerms) {
      if (_containsKeyword(value, term)) {
        return true;
      }
    }
    return false;
  }

  bool _containsKeyword(String value, String keyword) {
    final normalizedKeyword = _normalize(keyword);
    if (_isEnglish(normalizedKeyword)) {
      return RegExp(
        '(?:^|[^a-z0-9])${RegExp.escape(normalizedKeyword)}'
        r'(?=$|[^a-z0-9])',
      ).hasMatch(value);
    }
    return value.contains(normalizedKeyword);
  }

  bool _isEnglish(String value) {
    return RegExp(r'^[a-z0-9 _-]+$').hasMatch(value);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

final class _ExtractionSeed {
  const _ExtractionSeed({
    required this.type,
    required this.keyword,
    required this.hint,
    required this.plantHint,
    required this.tone,
    required this.fitScore,
    required this.category,
  });

  final String type;
  final String keyword;
  final String hint;
  final String plantHint;
  final String tone;
  final double fitScore;
  final String category;
}

const _seeds = <_ExtractionSeed>[
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '건조',
    hint: '공기가 건조한 날',
    plantHint: '잎 주변 수분을 살피기',
    tone: DailyKeywordTones.calm,
    fitScore: 0.80,
    category: 'dryness',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '습도',
    hint: '습도가 느껴지는 날',
    plantHint: '실내 공기 흐름을 살피기',
    tone: DailyKeywordTones.calm,
    fitScore: 0.72,
    category: 'humidity',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '비',
    hint: '비가 내리는 날',
    plantHint: '창가 빛 변화를 살피기',
    tone: DailyKeywordTones.gentle,
    fitScore: 0.75,
    category: 'rain',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '장맛비',
    hint: '비가 이어지는 때',
    plantHint: '실내 공기 흐름을 살피기',
    tone: DailyKeywordTones.cautious,
    fitScore: 0.82,
    category: 'monsoon_rain',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '폭염',
    hint: '더위가 강한 날',
    plantHint: '한낮 빛을 가볍게 의식하기',
    tone: DailyKeywordTones.cautious,
    fitScore: 0.90,
    category: 'heatwave',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '한파',
    hint: '찬 기운이 강한 날',
    plantHint: '창가 온도 변화를 살피기',
    tone: DailyKeywordTones.cautious,
    fitScore: 0.90,
    category: 'cold_wave',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '강풍',
    hint: '바람이 거센 날',
    plantHint: '잎 흔들림을 살피기',
    tone: DailyKeywordTones.cautious,
    fitScore: 0.80,
    category: 'strong_wind',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.weather,
    keyword: '미세먼지',
    hint: '공기 질이 답답한 날',
    plantHint: '잎 표면을 가볍게 살피기',
    tone: DailyKeywordTones.cautious,
    fitScore: 0.76,
    category: 'fine_dust',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.seasonal,
    keyword: '봄',
    hint: '봄기운이 느껴지는 때',
    plantHint: '새 잎을 가볍게 바라보기',
    tone: DailyKeywordTones.bright,
    fitScore: 0.70,
    category: 'season',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.seasonal,
    keyword: '여름',
    hint: '여름 기운이 이어지는 때',
    plantHint: '한낮 빛을 의식하기',
    tone: DailyKeywordTones.bright,
    fitScore: 0.70,
    category: 'season',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.seasonal,
    keyword: '가을',
    hint: '가을 공기가 느껴지는 때',
    plantHint: '차분한 빛을 바라보기',
    tone: DailyKeywordTones.calm,
    fitScore: 0.70,
    category: 'season',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.seasonal,
    keyword: '겨울',
    hint: '겨울 기운이 머무는 때',
    plantHint: '창가 온도를 의식하기',
    tone: DailyKeywordTones.calm,
    fitScore: 0.70,
    category: 'season',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '반려식물',
    hint: '반려식물을 가볍게 돌보는 이야기',
    plantHint: '새 잎과 흙 상태를 천천히 살피기',
    tone: DailyKeywordTones.gentle,
    fitScore: 0.84,
    category: 'plant_lifestyle',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '공원 산책',
    hint: '가까운 공원을 가볍게 걷는 이야기',
    plantHint: '바깥 초록을 함께 떠올리기',
    tone: DailyKeywordTones.bright,
    fitScore: 0.72,
    category: 'light_lifestyle',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '독서',
    hint: '책 한 권을 천천히 읽는 이야기',
    plantHint: '조용한 시간을 함께 보내기',
    tone: DailyKeywordTones.calm,
    fitScore: 0.68,
    category: 'light_lifestyle',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '전시회',
    hint: '가볍게 둘러볼 수 있는 전시 이야기',
    plantHint: '새로운 색과 모양을 함께 떠올리기',
    tone: DailyKeywordTones.bright,
    fitScore: 0.67,
    category: 'culture',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '분리배출',
    hint: '생활 속 분리배출을 실천하는 이야기',
    plantHint: '주변을 가볍게 정돈하기',
    tone: DailyKeywordTones.gentle,
    fitScore: 0.74,
    category: 'environmental_habit',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '재활용',
    hint: '생활 속 재활용을 돌아보는 이야기',
    plantHint: '오래 쓰는 물건을 함께 떠올리기',
    tone: DailyKeywordTones.gentle,
    fitScore: 0.70,
    category: 'environmental_habit',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '제로웨이스트',
    hint: '쓰레기를 줄이는 가벼운 생활 이야기',
    plantHint: '필요한 것만 천천히 고르기',
    tone: DailyKeywordTones.gentle,
    fitScore: 0.69,
    category: 'environmental_habit',
  ),
  _ExtractionSeed(
    type: DailyKeywordTypes.safeIssue,
    keyword: '플로깅',
    hint: '산책하며 주변을 정돈하는 이야기',
    plantHint: '깨끗한 바깥 공기를 함께 떠올리기',
    tone: DailyKeywordTones.bright,
    fitScore: 0.71,
    category: 'environmental_habit',
  ),
];

const _blockedTerms = <String>{
  '정치',
  '선거',
  '대통령',
  '국회',
  '정당',
  '범죄',
  '살인',
  '폭행',
  '강간',
  '강도',
  '흉기',
  '유괴',
  '전쟁',
  '전투',
  '무력 충돌',
  '폭격',
  '침공',
  '미사일',
  '사망 사고',
  '대형 사고',
  '참사',
  '붕괴',
  '추락사',
  'politics',
  'election',
  'crime',
  'murder',
  'assault',
  'violence',
  'war',
  'bombing',
  'invasion',
  'missile',
  'disaster',
};
