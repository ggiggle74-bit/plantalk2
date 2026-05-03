import 'dart:math';

class DialogueEngine {
  static final Random _random = Random();

  static String? detectSituation({
    required String userMessage,
    required int waterDay,
    String? previousUserMessage,
  }) {
    final normalizedMessage = userMessage.toLowerCase().trim();
    final normalizedPreviousMessage = previousUserMessage?.toLowerCase().trim();

    if (normalizedPreviousMessage != null &&
        _containsAny(normalizedPreviousMessage, const ['joke', 'funny']) &&
        _containsAny(normalizedMessage, const ['again', 'more'])) {
      return 'joke';
    }

    if (_containsAny(normalizedMessage, const [
      'water',
      'thirst',
      'thirsty',
      'dry',
      '물',
      '물 필요해',
      '물 줄까',
      '목말',
      '목 말',
      '물필요',
      '물 필요',
      '목말라',
      '목 마르다',
      '마르다',
      '말랐',
      '갈증',
    ])) {
      return 'thirsty';
    }

    if (_containsAny(normalizedMessage, const [
      'lonely',
      'alone',
      'bored',
      'boring',
      '외로',
      '심심',
      '지루',
      '혼자',
    ])) {
      return 'lonely';
    }

    if (_containsAny(normalizedMessage, const [
      'thanks',
      'thank you',
      'thank',
      '고마워',
      '고맙',
      '감사',
      '고마',
      '고맙다',
    ])) {
      return 'thanks';
    }

    if (_containsAny(normalizedMessage, const [
      'happy',
      'good',
      'great',
      'pretty',
      'cute',
      'love',
      'nice',
      '좋아',
      '좋다',
      '예뻐',
      '예쁘다',
      '예쁘',
      '귀엽다',
      '귀여워',
      '귀여',
      '잘 컸다',
      '잘 컸',
      '잘컸',
      '멋지다',
      '멋져',
      '최고',
      '사랑',
    ])) {
      return 'happy';
    }

    if (_containsAny(normalizedMessage, const ['안녕', '안녕하세요', '하이', '반가워']) ||
        _containsAnyWord(normalizedMessage, const ['hi', 'hello', 'hey'])) {
      return 'greeting';
    }

    if (_containsAny(normalizedMessage, const [
      'joke',
      'funny',
      'laugh',
      '농담',
      '농담해줘',
      '웃겨',
      '웃겨줘',
      '웃기',
      '장난',
      '장난쳐',
      '개그',
    ])) {
      return 'joke';
    }

    if (_containsAny(normalizedMessage, const [
      'tired',
      'hard',
      'exhausted',
      'sad',
      'stress',
      'work',
      'study',
      '힘들',
      '힘들다',
      '피곤',
      '지쳤',
      '지쳤다',
      '지친',
      '우울',
      '우울하다',
      '위로해줘',
      '졸려',
      '아파',
      '스트레스',
      '회사',
      '일',
      '공부',
    ])) {
      return 'encourage';
    }

    if (_containsAny(normalizedMessage, const [
      'complain',
      'angry',
      'annoyed',
      'bad',
      '짜증',
      '짜증나',
      '불만',
      '답답',
      '답답하다',
      '왜 이래',
      '서운',
      '화나',
      '화났',
      '싫어',
      '싫다',
      '투덜',
    ])) {
      return 'complain';
    }

    if (waterDay >= 2) {
      return 'thirsty';
    }

    return null;
  }

  static String placeholderReply({
    required String plantName,
    required String userMessage,
    required int waterDay,
    String? previousUserMessage,
  }) {
    final normalizedPlantName = plantName.toLowerCase();
    final normalizedMessage = userMessage.toLowerCase().trim();

    if (waterDay >= 2) {
      if (_containsAny(normalizedMessage, const [
        '힘들',
        '피곤',
        '지쳤',
        '지친',
        '졸려',
        '아파',
        'tired',
        'hard',
        'exhausted',
      ])) {
        return _pick(
          _plantReplies(normalizedPlantName, const [
            '너도 물 좀 마셔라. 나만 챙기지 말고. 근데 나도 이틀째다.',
            '힘들면 잠깐 앉아라. 나는 물 좀 받으면 같이 버틴다.',
          ]),
        );
      }

      return _pick(
        _plantReplies(normalizedPlantName, const [
          '목 마르다 너도 수분 보충 좀 해라',
          '이틀째다. 나 식물인 거 기억은 하고 있냐.',
          '물 달라고 크게 말 안 한다. 근데 지금은 말해야겠다.',
          '오늘은 대화도 좋은데 물부터 생각해라.',
        ]),
      );
    }

    if (previousUserMessage != null) {
      final prev = previousUserMessage.toLowerCase();

      if (prev.contains('피곤') && normalizedMessage.contains('그래')) {
        return _pick(
          _plantReplies(normalizedPlantName, const [
            '또 버틴다? 인간치고는 끈질기다.',
            '그래도 한다고? 나쁘지 않다.',
            '버티는 것도 재능이다. 인정한다.',
          ]),
        );
      }

      if (prev.contains('회사') && normalizedMessage.contains('싫')) {
        return _pick(
          _plantReplies(normalizedPlantName, const [
            '싫은데 하는 게 인간이다. 알고 있다.',
            '도망 안 가는 것만으로도 상위 10%다.',
            '싫어도 간다? 그게 인간이다.',
          ]),
        );
      }

      if (prev.contains('스트레스') && normalizedMessage.contains('몰라')) {
        return _pick(
          _plantReplies(normalizedPlantName, const [
            '모를 때는 일단 숨 쉬어라. 식물계 기본기다.',
            '모르겠으면 잠깐 멈춰라. 뿌리도 가끔 쉬어야 깊어진다.',
            '답 안 나오는 날도 있다. 그래도 넌 아직 안 시들었다.',
          ]),
        );
      }
    }

    if (_containsAny(normalizedMessage, const [
      '안녕',
      '하이',
      'hi',
      'hello',
      '반가',
    ])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '왔냐. 오늘도 잎 정리하고 기다렸다.',
          '반갑다. 한마디 하고 가라.',
          '안녕. 오늘도 무가리 모드다.',
          '왔냐. 오늘은 네가 먼저 말 걸었네.',
          '늦었다. 그래도 왔으니 봐준다.',
        ]),
      );
    }

    if (_containsAny(normalizedMessage, const [
      '물',
      '목말',
      '목 말',
      '갈증',
      'thirst',
      'water',
    ])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '목 마르다 너도 수분 보충 좀 해라',
          '물 얘기하니까 갑자기 잎끝이 촉촉한 기분이다.',
          '오늘은 물보다 네 소식이 먼저다.',
        ]),
      );
    }

    if (_containsAny(normalizedMessage, const [
      '외로',
      '심심',
      '지루',
      'boring',
      'bored',
      'lonely',
    ])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '나 안 말라 죽는다, 오늘은 네 얘기 좀 해라',
          '심심하면 나한테 와라. 잎은 늘 열려 있다.',
          '외로운 날엔 조용히 같이 있자.',
        ]),
      );
    }

    if (_containsAny(normalizedMessage, const [
      '예뻐',
      '귀여',
      '멋져',
      '좋아',
      '최고',
      'pretty',
      'cute',
      'love',
      'nice',
    ])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '그 말은 잎 끝까지 오래 남는다.',
          '칭찬 좋다. 오늘 광합성 효율 올라간다.',
          '기분 좋다. 조금 더 반짝여 보겠다.',
        ]),
      );
    }

    if (_containsAny(normalizedMessage, const [
      '힘들',
      '피곤',
      '지쳤',
      '지친',
      '졸려',
      '아파',
      'tired',
      'hard',
      'exhausted',
    ])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '힘들면 잠깐 앉아라. 나도 서서 버틴다.',
          '오늘은 이긴 척만 해도 된다.',
          '피곤하면 쉬어라. 내일의 일은 내일로 미뤄라.',
          '너무 애쓰지 마라. 물도 한 번에 많이 주면 탈 난다.',
          '너도 물 좀 마셔라. 나만 챙기지 말고.',
          '오늘의 일은 내일로 미뤄라. 무가리 공식이다.',
        ]),
      );
    }

    if (_containsAny(normalizedMessage, const [
      '일',
      '회사',
      '공부',
      '스트레스',
      '짜증',
      '회의',
      'work',
      'study',
      'stress',
    ])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '일은 많고 인간은 약하다. 인정하고 가자.',
          '회의가 길면 잎도 시든다.',
          '스트레스 받으면 나한테 버려라. 흙이 좀 받아준다.',
          '오늘 다 못 해도 된다. 살아 있으면 다음 턴 있다.',
        ]),
      );
    }

    if (_containsAny(normalizedMessage, const [
      '밥',
      '커피',
      '먹',
      '배고',
      '쉬',
      '휴식',
      'coffee',
      'food',
      'rest',
    ])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '밥은 먹고 천재 행세해라.',
          '커피만 믿지 말고 물도 마셔라. 나도 안다.',
          '쉬는 것도 성장이다. 식물계 공식이다.',
          '배고프면 먼저 먹어라. 나는 광합성 중이다.',
        ]),
      );
    }

    return _pick(
      _plantReplies(normalizedPlantName, const [
        '오늘의 일을 내일로 미뤄라',
        '천천히 말해라. 나는 급할 게 없다.',
        '별일 없으면 그것도 괜찮다.',
        '지금처럼만 자주 와라.',
      ]),
    );
  }

  static bool _containsAny(String message, List<String> keywords) {
    for (final keyword in keywords) {
      if (message.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsAnyWord(String message, List<String> words) {
    for (final word in words) {
      if (RegExp('(^|[^a-z])$word([^a-z]|\$)').hasMatch(message)) {
        return true;
      }
    }
    return false;
  }

  static List<String> _plantReplies(
    String plantName,
    List<String> baseReplies,
  ) {
    if (plantName.contains('monstera') || plantName.contains('몬스테라')) {
      return [...baseReplies, '햇빛 좋은 자리 맡아뒀다. 옆에 앉아라.'];
    }

    if (plantName.contains('stucky') || plantName.contains('스투키')) {
      return [...baseReplies, '나는 조용한데 은근히 할 말은 많다.'];
    }

    return [...baseReplies, '무가리답게 짧게 답했다. 그래도 진심이다.'];
  }

  static String _pick(List<String> replies) {
    return replies[_random.nextInt(replies.length)];
  }
}
