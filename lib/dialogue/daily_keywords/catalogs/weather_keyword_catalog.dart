import '../models/daily_keyword_candidate.dart';

class WeatherKeywordCatalog {
  WeatherKeywordCatalog._();

  static const entries = <DailyKeywordCandidate>[
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '건조',
      hint: '공기가 건조한 날',
      plantHint: '잎 주변 수분을 살피기',
      tone: DailyKeywordTones.calm,
      fitScore: 0.80,
      category: 'dryness',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '습도',
      hint: '습도가 느껴지는 날',
      plantHint: '실내 공기 흐름을 살피기',
      tone: DailyKeywordTones.calm,
      fitScore: 0.72,
      category: 'humidity',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '비',
      hint: '비가 내리는 날',
      plantHint: '창가 빛 변화를 살피기',
      tone: DailyKeywordTones.gentle,
      fitScore: 0.75,
      category: 'rain',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '장맛비',
      hint: '비가 이어지는 때',
      plantHint: '실내 공기 흐름을 살피기',
      tone: DailyKeywordTones.cautious,
      fitScore: 0.82,
      category: 'monsoon_rain',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '폭염',
      hint: '더위가 강한 날',
      plantHint: '한낮 빛을 가볍게 의식하기',
      tone: DailyKeywordTones.cautious,
      fitScore: 0.90,
      category: 'heatwave',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '한파',
      hint: '찬 기운이 강한 날',
      plantHint: '창가 온도 변화를 살피기',
      tone: DailyKeywordTones.cautious,
      fitScore: 0.90,
      category: 'cold_wave',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '강풍',
      hint: '바람이 거센 날',
      plantHint: '잎 흔들림을 살피기',
      tone: DailyKeywordTones.cautious,
      fitScore: 0.80,
      category: 'strong_wind',
    ),
    DailyKeywordCandidate(
      type: DailyKeywordTypes.weather,
      keyword: '미세먼지',
      hint: '공기 질이 답답한 날',
      plantHint: '잎 표면을 가볍게 살피기',
      tone: DailyKeywordTones.cautious,
      fitScore: 0.76,
      category: 'fine_dust',
    ),
  ];

  static List<DailyKeywordCandidate> candidatesFor(
    Iterable<String> weatherSignals,
  ) {
    final entriesByKeyword = {
      for (final entry in entries) _normalize(entry.keyword): entry,
    };
    final seenSignals = <String>{};
    final candidates = <DailyKeywordCandidate>[];

    for (final signal in weatherSignals) {
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
