import 'dart:math';

class DialogueEngine {
  static final Random _random = Random();

  static String placeholderReply({
    required String plantName,
    required String userMessage,
    required int waterDay,
  }) {
    final normalizedPlantName = plantName.toLowerCase();
    final normalizedMessage = userMessage.toLowerCase().trim();

    if (waterDay >= 2) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '목 마르다 너도 수분 보충 좀 해라',
          '이틀째다. 나 식물인 거 기억은 하고 있냐.',
          '물 달라고 크게 말 안 한다. 근데 지금은 말해야겠다.',
          '오늘은 대화도 좋은데 물부터 생각해라.',
        ]),
      );
    }

    if (_containsAny(normalizedMessage, const ['안녕', 'hi', 'hello', '반가'])) {
      return _pick(
        _plantReplies(normalizedPlantName, const [
          '왔냐. 오늘도 잎 정리하고 기다렸다.',
          '반갑다. 한마디 하고 가라.',
          '안녕. 오늘도 무가리 모드다.',
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
