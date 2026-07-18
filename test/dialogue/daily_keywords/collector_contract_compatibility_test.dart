import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/daily_keywords/models/daily_keyword_candidate.dart';
import 'package:plantalk2/dialogue/models/daily_keyword_context.dart';

void main() {
  test('collector v1 payload maps to existing Plantalk keyword fields', () {
    final source = File(
      'tools/mugari_daily_context_collector/example/'
      'daily_keyword_context.json',
    ).readAsStringSync();
    final document = _stringKeyedMap(jsonDecode(source));
    final keywordValues = document['keywords'];

    expect(document['schemaVersion'], 'daily-keyword-context/v1');
    expect(keywordValues, isA<List<Object?>>());

    final entries = (keywordValues! as List<Object?>).map((value) {
      final keyword = _stringKeyedMap(value);
      final angles = keyword['conversationAngles'];

      expect(angles, isA<List<Object?>>());
      expect(angles as List<Object?>, isNotEmpty);

      return DailyKeywordEntry(
        type: keyword['type']! as String,
        keyword: keyword['keyword']! as String,
        hint: keyword['hint']! as String,
        category: keyword['category'] as String?,
        relevanceScore: (keyword['relevanceScore'] as num?)?.toDouble(),
        plantHint: keyword['plantHint']! as String,
        tone: keyword['tone']! as String,
        fitScore: (keyword['fitScore']! as num).toDouble(),
      );
    }).toList();

    expect(entries, isNotEmpty);
    for (final entry in entries) {
      expect(DailyKeywordTypes.allowed, contains(entry.type));
      expect(DailyKeywordTones.allowed, contains(entry.tone));
      expect(entry.keyword.trim(), isNotEmpty);
      expect(entry.hint.trim(), isNotEmpty);
      expect(entry.plantHint?.trim(), isNotEmpty);
      expect(entry.fitScore, greaterThanOrEqualTo(0.60));
      expect(entry.fitScore, lessThanOrEqualTo(1.0));
    }
  });
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  expect(value, isA<Map<Object?, Object?>>());
  final map = value! as Map<Object?, Object?>;
  return {
    for (final entry in map.entries) entry.key! as String: entry.value,
  };
}
