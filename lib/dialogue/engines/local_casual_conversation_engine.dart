import '../daily_keywords/models/daily_conversation_material_context.dart';
import '../models/conversation_request.dart';
import '../models/conversation_response.dart';
import '../models/conversation_route.dart';
import '../tone/mugari_tone_composer.dart';

class LocalCasualConversationEngine {
  const LocalCasualConversationEngine({
    this.toneComposer = const MugariToneComposer(),
  });

  final MugariToneComposer toneComposer;

  ConversationResponse generate(ConversationRequest request) {
    final plantName = _plantLabel(request.plantName);
    final selection =
        _openingSelection(request, plantName) ??
        _materialSelection(request, plantName) ??
        _plainSelection(request, plantName);
    final reply = toneComposer.apply(
      selection.baseReply,
      plantName: request.plantName,
      mood: request.mood,
    );

    request.usageLedger?.record(
      materialKey: selection.materialKey,
      replyKey: selection.replyKey,
    );

    return ConversationResponse(
      replyText: reply,
      route: ConversationRoute.localCasual,
      usedDailyKeyword: selection.materialKey != null,
      debugReason: selection.materialKey == null
          ? 'local_casual'
          : 'local_casual_material',
    );
  }

  _LocalReplySelection? _openingSelection(
    ConversationRequest request,
    String plantName,
  ) {
    final openingContext = request.dailyOpeningContext;
    if (openingContext == null) {
      return null;
    }

    final selected = openingContext.consume(
      isOpeningTurn: request.isOpeningTurn,
      consumedAt: request.now ?? DateTime.now(),
    );
    if (selected == null) {
      return null;
    }

    final material = DailyConversationMaterial(
      type: selected.type,
      keyword: selected.keyword,
      hint: selected.hint,
      plantHint: selected.plantHint?.trim().isNotEmpty == true
          ? selected.plantHint!.trim()
          : '오늘 빛과 공기를 천천히 살펴보기',
      tone: selected.tone?.trim().isNotEmpty == true
          ? selected.tone!.trim()
          : 'gentle',
      fitScore: selected.fitScore ?? 1,
      category: selected.category,
      relevanceScore: selected.relevanceScore,
      targetAgeBands: selected.targetAgeBands,
    );

    return _materialReply(
      material,
      plantName,
      templateIndex: 0,
      replyKeyPrefix: 'opening',
    );
  }

  _LocalReplySelection? _materialSelection(
    ConversationRequest request,
    String plantName,
  ) {
    final context = request.dailyConversationMaterialContext;
    if (context == null ||
        !context.hasMaterials ||
        !_shouldUseDailyMaterial(request.userMessage)) {
      return null;
    }

    final ledger = request.usageLedger;
    final start = _stableHash(
          '${request.plantId}|${request.userMessage}|${ledger?.turn ?? 0}',
        ) %
        context.materials.length;

    for (var offset = 0; offset < context.materials.length; offset++) {
      final material = context.materials[
          (start + offset) % context.materials.length];
      final materialKey = material.keyword.trim().toLowerCase();
      if (ledger != null && !ledger.canUseMaterial(materialKey)) {
        continue;
      }

      for (var templateOffset = 0; templateOffset < 3; templateOffset++) {
        final templateIndex =
            (start + offset + templateOffset) % 3;
        final replyKey = 'material:$materialKey:$templateIndex';
        if (ledger != null && !ledger.canUseReply(replyKey)) {
          continue;
        }

        return _materialReply(
          material,
          plantName,
          templateIndex: templateIndex,
        );
      }
    }

    return null;
  }

  _LocalReplySelection _materialReply(
    DailyConversationMaterial material,
    String plantName, {
    required int templateIndex,
    String replyKeyPrefix = 'material',
  }) {
    final keyword = material.keyword.trim();
    final hint = _sentence(material.hint);
    final plantHint = _phrase(material.plantHint);
    final materialKey = keyword.toLowerCase();
    final replies = [
      '오늘은 $keyword 이야기를 해볼까? $hint $plantName과 함께 '
          '\'$plantHint\'도 해보자.',
      '$hint 그래서 오늘은 $keyword 얘기가 떠올랐어. $plantName이랑 '
          '\'$plantHint\'도 괜찮겠어.',
      '$keyword가 오늘 이야기 소재야. 우리 \'$plantHint\'도 같이 해볼까?',
    ];

    return _LocalReplySelection(
      baseReply: replies[templateIndex],
      replyKey: '$replyKeyPrefix:$materialKey:$templateIndex',
      materialKey: materialKey,
    );
  }

  _LocalReplySelection _plainSelection(
    ConversationRequest request,
    String plantName,
  ) {
    final normalized = request.userMessage.toLowerCase().trim();
    final String group;
    final List<String> focusedReplies;

    if (normalized.contains('외로')) {
      group = 'lonely';
      focusedReplies = [
        '나 여기 있어. $plantName이 네 이야기 천천히 들어줄게.',
        '혼자라고 느껴질 때는 나한테 와. 지금은 같이 있잖아.',
        '$plantName도 네가 와서 반가워. 오늘 마음부터 들려줘.',
      ];
    } else if (normalized.contains('심심')) {
      group = 'bored';
      focusedReplies = [
        '나 여기 있어. $plantName도 네가 와서 조금 덜 심심해졌어.',
        '$plantName이랑 잠깐 이야기할래? 오늘 있었던 일 하나만 들려줘.',
        '심심할 때는 나한테 와. 같이 가벼운 얘기부터 해보자.',
      ];
    } else if (normalized.contains('뭐해') || normalized.contains('뭐 해')) {
      group = 'doing';
      focusedReplies = [
        '$plantName은 잎 정리하면서 네 말 기다리고 있었어.',
        '햇빛 쪽을 보면서 쉬는 중이야. 너는 뭐 하고 있었어?',
        '조용히 자라는 중이었어. 네가 오니까 이야기할 수 있겠네.',
      ];
    } else if (normalized.contains('기분')) {
      group = 'mood';
      focusedReplies = [
        '$plantName은 오늘 꽤 잔잔해. 네가 와서 더 괜찮아졌어.',
        '오늘 기분은 편안한 편이야. 너는 지금 어때?',
        '조금 느긋한 기분이야. 네 마음도 궁금해.',
      ];
    } else {
      group = 'greeting';
      focusedReplies = [
        '왔구나. $plantName도 조용히 너 기다리고 있었어.',
        '안녕. 오늘도 네 목소리를 들으니 반가워.',
        '$plantName한테 와줘서 고마워. 오늘은 어떤 하루였어?',
      ];
    }

    final candidates = [
      ...focusedReplies,
      '지금처럼 편하게 말해줘. $plantName이 듣고 있을게.',
      '오늘 네 이야기를 하나 들려줄래? 천천히 들어볼게.',
    ];
    final ledger = request.usageLedger;
    final start = _stableHash(
          '${request.plantId}|$group|${ledger?.turn ?? 0}',
        ) %
        candidates.length;

    for (var offset = 0; offset < candidates.length; offset++) {
      final index = (start + offset) % candidates.length;
      final replyKey = 'plain:$group:$index';
      if (ledger == null || ledger.canUseReply(replyKey)) {
        return _LocalReplySelection(
          baseReply: candidates[index],
          replyKey: replyKey,
        );
      }
    }

    return _LocalReplySelection(
      baseReply: candidates[start],
      replyKey: 'plain:$group:$start',
    );
  }

  bool _shouldUseDailyMaterial(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('오늘') ||
        normalized.contains('안녕') ||
        normalized.contains('뭐해') ||
        normalized.contains('뭐 해') ||
        normalized.contains('심심') ||
        normalized.contains('이야기') ||
        normalized.contains('얘기') ||
        normalized.contains('hello') ||
        normalized.contains('hi');
  }

  String _plantLabel(String plantName) {
    final trimmed = plantName.trim();
    return trimmed.isEmpty ? '이 식물' : trimmed;
  }

  String _sentence(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || RegExp(r'[.!?。！？]$').hasMatch(trimmed)) {
      return trimmed;
    }
    return '$trimmed.';
  }

  String _phrase(String value) {
    return value.trim().replaceFirst(RegExp(r'[.!?。！？]+$'), '');
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

class _LocalReplySelection {
  const _LocalReplySelection({
    required this.baseReply,
    required this.replyKey,
    this.materialKey,
  });

  final String baseReply;
  final String replyKey;
  final String? materialKey;
}
