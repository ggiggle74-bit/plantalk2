import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class DialogueService {
  DialogueService({SupabaseClient? client, Random? random})
    : _client = client ?? Supabase.instance.client,
      _random = random ?? Random();

  static const Set<String> _draftMoveSituations = {
    'greeting',
    'smalltalk',
    'thirsty',
    'lonely',
    'thanks',
    'happy',
    'growth_happy',
    'care_ack',
    'condition_watch',
    'joke',
    'encourage',
    'complain',
    'goodnight',
    'fallback',
  };

  final SupabaseClient _client;
  final Random _random;

  Future<List<Map<String, dynamic>>> fetchDraftDialogueCandidates() async {
    final data = await _client
        .from('dialogues')
        .select('id, text')
        .eq('situation', 'draft')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> moveDraftDialogueCandidate({
    required Object id,
    required String situation,
  }) async {
    if (!_draftMoveSituations.contains(situation)) {
      throw ArgumentError.value(situation, 'situation', 'Invalid situation');
    }

    final updatedRows = await _client
        .from('dialogues')
        .update({'situation': situation})
        .eq('id', id)
        .eq('situation', 'draft')
        .select('id');

    if (updatedRows.isEmpty) {
      throw StateError('No draft dialogue row was updated.');
    }
  }

  Future<String?> fetchRandomReply({
    String? situation,
    String locale = 'ko',
    String? conditionKey,
    String? personalityKey,
    String? toneKey,
  }) async {
    final normalizedSituation = _normalizeKey(situation);

    if (normalizedSituation == null || normalizedSituation == 'draft') {
      return null;
    }

    final normalizedLocale = _normalizeKey(locale) ?? 'ko';
    final normalizedConditionKey = _normalizeKey(conditionKey);
    final normalizedPersonalityKey = _normalizeKey(personalityKey);
    final normalizedToneKey = _normalizeKey(toneKey);

    try {
      final reply = await _fetchAuthoredReply(
        locale: normalizedLocale,
        situation: normalizedSituation,
        conditionKey: normalizedConditionKey,
        personalityKey: normalizedPersonalityKey,
        toneKey: normalizedToneKey,
      );

      if (reply != null) {
        return reply;
      }
    } on PostgrestException {
      // The new authoring table is optional during rollout. If it has not been
      // migrated yet, keep the existing legacy dialogue path working.
    }

    return _fetchLegacyRandomReply(normalizedSituation);
  }

  Future<String?> _fetchAuthoredReply({
    required String locale,
    required String situation,
    String? conditionKey,
    String? personalityKey,
    String? toneKey,
  }) async {
    final data = await _client
        .from('dialogue_replies')
        .select(
          'reply_text, weight, priority, condition_key, personality_key, tone_key',
        )
        .eq('locale', locale)
        .eq('enabled', true)
        .eq('review_status', 'approved')
        .eq('situation_key', situation)
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    final candidates = List<Map<String, dynamic>>.from(data)
        .map(_DialogueReplyCandidate.fromRow)
        .whereType<_DialogueReplyCandidate>()
        .where(
          (candidate) => candidate.matches(
            conditionKey: conditionKey,
            personalityKey: personalityKey,
            toneKey: toneKey,
          ),
        )
        .toList();

    if (candidates.isEmpty) {
      return null;
    }

    final bestSpecificity = candidates
        .map(
          (candidate) => candidate.specificityScore(
            conditionKey: conditionKey,
            personalityKey: personalityKey,
            toneKey: toneKey,
          ),
        )
        .reduce(max);

    final mostSpecificCandidates = candidates
        .where(
          (candidate) =>
              candidate.specificityScore(
                conditionKey: conditionKey,
                personalityKey: personalityKey,
                toneKey: toneKey,
              ) ==
              bestSpecificity,
        )
        .toList();

    final bestPriority = mostSpecificCandidates
        .map((candidate) => candidate.priority)
        .reduce(max);

    final highestPriorityCandidates = mostSpecificCandidates
        .where((candidate) => candidate.priority == bestPriority)
        .toList();

    return _pickWeighted(highestPriorityCandidates);
  }

  Future<String?> _fetchLegacyRandomReply(String situation) async {
    final data = await _client
        .from('dialogues')
        .select('text, created_at')
        .eq('situation', situation)
        .order('created_at', ascending: false);

    final replies = data
        .map((row) => row['text'] as String?)
        .whereType<String>()
        .where((text) => text.trim().isNotEmpty)
        .toList();

    if (replies.isEmpty) {
      return null;
    }

    return replies[_random.nextInt(replies.length)];
  }

  String _pickWeighted(List<_DialogueReplyCandidate> candidates) {
    final totalWeight = candidates.fold<int>(
      0,
      (total, candidate) => total + candidate.weight,
    );

    if (totalWeight <= 0) {
      return candidates[_random.nextInt(candidates.length)].replyText;
    }

    var ticket = _random.nextInt(totalWeight);
    for (final candidate in candidates) {
      ticket -= candidate.weight;
      if (ticket < 0) {
        return candidate.replyText;
      }
    }

    return candidates.last.replyText;
  }
}

class _DialogueReplyCandidate {
  const _DialogueReplyCandidate({
    required this.replyText,
    required this.weight,
    required this.priority,
    this.conditionKey,
    this.personalityKey,
    this.toneKey,
  });

  final String replyText;
  final int weight;
  final int priority;
  final String? conditionKey;
  final String? personalityKey;
  final String? toneKey;

  static _DialogueReplyCandidate? fromRow(Map<String, dynamic> row) {
    final replyText = _trimmedOrNull(row['reply_text']);
    if (replyText == null) {
      return null;
    }

    return _DialogueReplyCandidate(
      replyText: replyText,
      weight: _positiveIntOrDefault(row['weight'], 100),
      priority: _intOrDefault(row['priority'], 0),
      conditionKey: _normalizeKey(row['condition_key']),
      personalityKey: _normalizeKey(row['personality_key']),
      toneKey: _normalizeKey(row['tone_key']),
    );
  }

  bool matches({
    String? conditionKey,
    String? personalityKey,
    String? toneKey,
  }) {
    return _matchesOptionalKey(conditionKey, this.conditionKey) &&
        _matchesOptionalKey(personalityKey, this.personalityKey) &&
        _matchesOptionalKey(toneKey, this.toneKey);
  }

  int specificityScore({
    String? conditionKey,
    String? personalityKey,
    String? toneKey,
  }) {
    var score = 0;

    if (conditionKey != null && this.conditionKey == conditionKey) {
      score += 4;
    }
    if (personalityKey != null && this.personalityKey == personalityKey) {
      score += 2;
    }
    if (toneKey != null && this.toneKey == toneKey) {
      score += 1;
    }

    return score;
  }

  static bool _matchesOptionalKey(String? expected, String? actual) {
    if (expected == null) {
      return actual == null;
    }

    return actual == null || actual == expected;
  }
}

String? _normalizeKey(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _trimmedOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _intOrDefault(Object? value, int fallback) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int _positiveIntOrDefault(Object? value, int fallback) {
  final parsed = _intOrDefault(value, fallback);
  return parsed > 0 ? parsed : fallback;
}
