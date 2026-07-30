import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('condition memory model owns the seven-day freshness rule', () {
    final source = File(
      'lib/models/latest_condition_memory.dart',
    ).readAsStringSync();

    expect(source, contains('Duration(days: 7)'));
    expect(source, contains("row['created_at']"));
    expect(source, contains('timestamp.toUtc()'));
    expect(source, contains('utcNow.subtract(maximumAge)'));
  });

  test('stored condition memory fails closed without a valid timestamp', () {
    final source = File('lib/services/plant_service.dart').readAsStringSync();

    expect(source, contains('created_at'));
    expect(source, contains('latest.checkedAt == null'));
    expect(source, contains('!latest.isFreshAt(now ?? DateTime.now())'));
  });

  test('controller filters request memory before choosing a reply path', () {
    final source = File(
      'lib/dialogue/chat_panel_conversation_controller.dart',
    ).readAsStringSync();

    expect(source, contains('_freshConditionMemory(request)'));
    expect(source, contains('conditionMemoryUnavailableReply'));
    expect(source, isNot(contains('PlantService')));
    expect(source.toLowerCase(), isNot(contains('supabase')));
  });

  test('composition root does not own condition freshness decisions', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, isNot(contains('conversationFreshnessWindow')));
    expect(source, isNot(contains('isFreshAt(')));
  });
}
