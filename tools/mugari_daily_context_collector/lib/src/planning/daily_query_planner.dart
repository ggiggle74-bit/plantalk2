import '../models/daily_keyword_candidate.dart';
import 'daily_search_query.dart';

final class DailyQueryPlanner {
  const DailyQueryPlanner({
    this.maximumQueries = 9,
    this.maximumAudienceQueries = 2,
  });

  final int maximumQueries;
  final int maximumAudienceQueries;

  DailyQueryPlan plan(DailyQueryPlanRequest request) {
    if (maximumQueries < 6) {
      throw StateError('maximumQueries must allow the six general queries.');
    }
    if (maximumAudienceQueries < 0) {
      throw StateError('maximumAudienceQueries must not be negative.');
    }

    final isKorean = request.locale.toLowerCase().startsWith('ko');
    final queries = <DailySearchQuery>[
      DailySearchQuery(
        id: 'weather-daily',
        text: isKorean ? '오늘 날씨 생활' : 'today weather daily life',
        intent: DailyQueryIntents.weather,
        priority: 100,
        freshnessWindowDays: 2,
      ),
      DailySearchQuery(
        id: 'nature-daily',
        text: isKorean ? '오늘 자연 식물' : 'today nature plants',
        intent: DailyQueryIntents.nature,
        priority: 95,
        freshnessWindowDays: 7,
      ),
      DailySearchQuery(
        id: 'seasonal-monthly',
        text: _seasonalQuery(request.date, isKorean: isKorean),
        intent: DailyQueryIntents.seasonal,
        priority: 90,
        freshnessWindowDays: 31,
      ),
      DailySearchQuery(
        id: 'park-weekly',
        text: isKorean
            ? '이번 주 공원 산책 자연'
            : 'this week park walk nature',
        intent: DailyQueryIntents.park,
        priority: 85,
        freshnessWindowDays: 7,
      ),
      DailySearchQuery(
        id: 'environment-weekly',
        text: isKorean
            ? '이번 주 환경 생활 재활용'
            : 'this week environment recycling daily life',
        intent: DailyQueryIntents.environment,
        priority: 80,
        freshnessWindowDays: 7,
      ),
      DailySearchQuery(
        id: 'culture-weekly',
        text: isKorean
            ? '이번 주 전시 독서 문화'
            : 'this week exhibitions books culture',
        intent: DailyQueryIntents.culture,
        priority: 75,
        freshnessWindowDays: 14,
      ),
    ];

    final regionLabel = request.regionLabel;
    if (regionLabel != null) {
      queries.add(
        DailySearchQuery(
          id: 'region-weekly',
          text: isKorean
              ? '$regionLabel 이번 주 공원 문화 행사'
              : '$regionLabel this week parks culture events',
          intent: DailyQueryIntents.region,
          priority: 88,
          freshnessWindowDays: 7,
          regionScoped: true,
        ),
      );
    }

    for (final ageBand in _audienceBandsFor(request)) {
      queries.add(
        DailySearchQuery(
          id: 'audience-${ageBand.replaceAll('_', '-')}',
          text: _audienceQuery(ageBand, isKorean: isKorean),
          intent: DailyQueryIntents.audience,
          priority: 70,
          freshnessWindowDays: 14,
          targetAgeBands: [ageBand],
        ),
      );
    }

    final uniqueQueries = <String, DailySearchQuery>{};
    for (final query in queries) {
      _assertSafeQuery(query.text);
      final normalizedText = query.text.toLowerCase();
      uniqueQueries.putIfAbsent(normalizedText, () => query);
    }

    final ordered = uniqueQueries.values.toList()
      ..sort((left, right) {
        final byPriority = right.priority.compareTo(left.priority);
        return byPriority != 0 ? byPriority : left.id.compareTo(right.id);
      });

    return DailyQueryPlan(
      request: request,
      queries: ordered.take(maximumQueries),
    );
  }

  List<String> _audienceBandsFor(DailyQueryPlanRequest request) {
    final ageBands = request.targetAgeBands;
    if (maximumAudienceQueries == 0 || ageBands.isEmpty) {
      return const [];
    }
    if (ageBands.length <= maximumAudienceQueries) {
      return ageBands;
    }

    final daysFromEpoch = request.date.difference(DateTime.utc(2020)).inDays;
    final start = daysFromEpoch.remainder(ageBands.length).abs();
    return List.generate(
      maximumAudienceQueries,
      (index) => ageBands[(start + index) % ageBands.length],
      growable: false,
    );
  }

  String _seasonalQuery(DateTime date, {required bool isKorean}) {
    final season = _seasonFor(date.month, isKorean: isKorean);
    if (isKorean) {
      return '${date.month}월 $season 계절 식물';
    }
    return '${_englishMonth(date.month)} $season seasonal plants';
  }

  String _seasonFor(int month, {required bool isKorean}) {
    if (month == 12 || month <= 2) {
      return isKorean ? '겨울' : 'winter';
    }
    if (month <= 5) {
      return isKorean ? '봄' : 'spring';
    }
    if (month <= 8) {
      return isKorean ? '여름' : 'summer';
    }
    return isKorean ? '가을' : 'autumn';
  }

  String _audienceQuery(String ageBand, {required bool isKorean}) {
    final label = isKorean
        ? _koreanAgeLabel(ageBand)
        : _englishAgeLabel(ageBand);
    return isKorean
        ? '이번 주 $label 취미 문화 산책'
        : 'this week $label hobbies culture walks';
  }

  String _koreanAgeLabel(String ageBand) {
    return switch (ageBand) {
      DailyKeywordAgeBands.teens => '10대',
      DailyKeywordAgeBands.twenties => '20대',
      DailyKeywordAgeBands.thirties => '30대',
      DailyKeywordAgeBands.forties => '40대',
      DailyKeywordAgeBands.fifties => '50대',
      DailyKeywordAgeBands.sixtiesPlus => '60대 이상',
      _ => throw ArgumentError.value(ageBand, 'ageBand', 'is not supported'),
    };
  }

  String _englishAgeLabel(String ageBand) {
    return switch (ageBand) {
      DailyKeywordAgeBands.teens => 'teens',
      DailyKeywordAgeBands.twenties => 'people in their 20s',
      DailyKeywordAgeBands.thirties => 'people in their 30s',
      DailyKeywordAgeBands.forties => 'people in their 40s',
      DailyKeywordAgeBands.fifties => 'people in their 50s',
      DailyKeywordAgeBands.sixtiesPlus => 'people aged 60 and over',
      _ => throw ArgumentError.value(ageBand, 'ageBand', 'is not supported'),
    };
  }

  String _englishMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _assertSafeQuery(String query) {
    final normalized = query.toLowerCase();
    const forbiddenKoreanTerms = [
      '뉴스',
      '실시간',
      '사건',
      '사고',
      '정치',
      '범죄',
      '전쟁',
    ];
    for (final term in forbiddenKoreanTerms) {
      if (normalized.contains(term)) {
        throw StateError('Unsafe query template contains a blocked term: $term');
      }
    }

    final englishWords = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'));
    const forbiddenEnglishWords = {'news', 'breaking', 'crime', 'war'};
    for (final word in englishWords) {
      if (forbiddenEnglishWords.contains(word)) {
        throw StateError('Unsafe query template contains a blocked word: $word');
      }
    }
  }
}
