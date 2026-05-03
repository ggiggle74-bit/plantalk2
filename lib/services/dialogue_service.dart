import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class DialogueService {
  DialogueService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

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
