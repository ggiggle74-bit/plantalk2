import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class DialogueService {
  DialogueService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final Random _random = Random();

  Future<String?> fetchRandomReply({String? situation}) async {
    final normalizedSituation = situation?.trim();
    final List<dynamic> data;

    if (normalizedSituation == null || normalizedSituation.isEmpty) {
      data = await _client.from('dialogues').select('text');
    } else {
      data = await _client
          .from('dialogues')
          .select('text')
          .eq('situation', normalizedSituation);
    }

    final replies = data
        .map((row) => row is Map ? row['text'] : null)
        .whereType<String>()
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (replies.isEmpty) {
      return null;
    }

    return replies[_random.nextInt(replies.length)];
  }
}
