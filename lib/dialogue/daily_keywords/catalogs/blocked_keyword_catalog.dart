import '../models/daily_keyword_candidate.dart';

class BlockedKeywordCatalog {
  BlockedKeywordCatalog._();

  static const blockedTerms = <String>{
    '정치',
    '선거',
    '대통령',
    '국회',
    '정당',
    'politics',
    'politician',
    'election',
    'campaign',
    '범죄',
    '살인',
    '폭행',
    '강간',
    '강도',
    '흉기',
    '유괴',
    'murder',
    'homicide',
    'assault',
    'violence',
    'violent_crime',
    'rape',
    'robbery',
    'kidnapping',
    'stabbing',
    '전쟁',
    '전투',
    '무력 충돌',
    '폭격',
    '침공',
    'war',
    'armed conflict',
    'bombing',
    'invasion',
    'missile',
    '사망 사고',
    '대형 사고',
    '참사',
    '붕괴',
    '추락사',
    'death accident',
    'fatal accident',
    'disaster',
    'collapse',
    '엽기',
    '충격 사건',
    '강력 사건',
    '연쇄살인',
    'sensational crime',
    'serial killer',
  };

  static bool blocks(DailyKeywordCandidate candidate) {
    return [
      candidate.keyword,
      candidate.hint,
      candidate.plantHint,
      candidate.category ?? '',
    ].any(containsBlockedTerm);
  }

  static bool containsBlockedTerm(String value) {
    final normalized = _normalize(value);
    return blockedTerms.any((term) {
      if (!_isEnglishTerm(term)) {
        return normalized.contains(term);
      }

      return _englishTermPattern(term).hasMatch(normalized);
    });
  }

  static bool _isEnglishTerm(String term) {
    return RegExp(r'^[a-z0-9 _-]+$').hasMatch(term);
  }

  static RegExp _englishTermPattern(String term) {
    return RegExp('(?:^|[^a-z0-9])${RegExp.escape(term)}(?=\$|[^a-z0-9])');
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
