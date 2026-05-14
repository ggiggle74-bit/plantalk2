import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class DialogueService {
  DialogueService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const Set<String> _draftMoveSituations = {
    'greeting',
    'thirsty',
    'lonely',
    'thanks',
    'happy',
    'joke',
    'encourage',
    'complain',
  };

  final SupabaseClient _client;

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

  Future<String?> fetchRandomReply({String? situation}) async {
    final normalizedSituation = situation?.trim();

    if (normalizedSituation == null ||
        normalizedSituation.isEmpty ||
        normalizedSituation == 'draft') {
      return null;
    }

    final data = await _client
        .from('dialogues')
        .select('text, created_at')
        .eq('situation', normalizedSituation)
        .order('created_at', ascending: false);

    final replies = data
        .map((row) => row['text'] as String?)
        .whereType<String>()
        .where((text) => text.trim().isNotEmpty)
        .toList();

    if (replies.isEmpty) {
      return null;
    }

    final random = Random();
    return replies[random.nextInt(replies.length)];
  }
}
