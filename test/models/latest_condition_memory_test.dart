import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  final now = DateTime.utc(2026, 7, 30, 12);

  test('parses and keeps the condition check timestamp from storage', () {
    final memory = LatestConditionMemory.fromRow({
      'message': '지금은 큰 이상이 없어 보여요.',
      'event_type': 'normal',
      'created_at': '2026-07-30T11:30:00+00:00',
    });

    expect(memory, isNotNull);
    expect(memory!.checkedAt, DateTime.utc(2026, 7, 30, 11, 30));
  });

  test('accepts condition memory inside the seven-day window', () {
    final memory = LatestConditionMemory(
      message: '괜찮아 보여요.',
      eventType: 'normal',
      checkedAt: now.subtract(const Duration(days: 6, hours: 23)),
    );

    expect(memory.isFreshAt(now), isTrue);
  });

  test('accepts condition memory exactly seven days old', () {
    final memory = LatestConditionMemory(
      message: '괜찮아 보여요.',
      eventType: 'normal',
      checkedAt: now.subtract(const Duration(days: 7)),
    );

    expect(memory.isFreshAt(now), isTrue);
  });

  test('rejects condition memory older than seven days', () {
    final memory = LatestConditionMemory(
      message: '예전에는 괜찮아 보였어요.',
      eventType: 'normal',
      checkedAt: now.subtract(const Duration(days: 7, microseconds: 1)),
    );

    expect(memory.isFreshAt(now), isFalse);
  });

  test('rejects a future condition timestamp', () {
    final memory = LatestConditionMemory(
      message: '시간이 잘못된 기록이에요.',
      eventType: 'uncertain',
      checkedAt: now.add(const Duration(minutes: 1)),
    );

    expect(memory.isFreshAt(now), isFalse);
  });

  test('keeps an immediate in-memory result without a stored timestamp', () {
    const memory = LatestConditionMemory(
      message: '방금 확인한 상태예요.',
      eventType: 'normal',
    );

    expect(memory.isFreshAt(now), isTrue);
  });

  test('rejects a negative freshness window', () {
    const memory = LatestConditionMemory(
      message: '상태 기록',
      eventType: 'normal',
    );

    expect(
      () => memory.isFreshAt(now, maximumAge: const Duration(seconds: -1)),
      throwsArgumentError,
    );
  });
}
