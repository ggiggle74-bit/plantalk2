import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  testWidgets('ChatPanel hides stale initial condition memory', (tester) async {
    const staleMarker = 'STALE_INITIAL_CONDITION_MARKER';

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPanel(
          plantName: '초록이',
          initialPlantMessage: '',
          waterDay: 0,
          initialConditionMemory: LatestConditionMemory(
            message: staleMarker,
            eventType: 'normal',
            checkedAt: DateTime.utc(2026, 7, 1),
          ),
        ),
      ),
    );

    expect(find.textContaining(staleMarker), findsNothing);
    expect(find.textContaining('최근 상태 확인:'), findsNothing);
    expect(find.text('종류 미확인'), findsOneWidget);
  });

  testWidgets('stale initial memory does not block a fresh reload', (
    tester,
  ) async {
    const staleMarker = 'STALE_INITIAL_CONDITION_MARKER';
    const freshMarker = 'FRESH_RELOADED_CONDITION_MARKER';
    var fetchCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPanel(
          plantId: 'plant-1',
          plantName: '초록이',
          initialPlantMessage: '',
          waterDay: 0,
          initialConditionMemory: const LatestConditionMemory(
            message: staleMarker,
            eventType: 'normal',
            checkedAt: DateTime.utc(2026, 7, 1),
          ),
          fetchLatestConditionMemory: (_) async {
            fetchCount++;
            return LatestConditionMemory(
              message: freshMarker,
              eventType: 'normal',
              checkedAt: DateTime.now().subtract(const Duration(days: 1)),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fetchCount, 1);
    expect(find.textContaining(staleMarker), findsNothing);
    expect(find.textContaining(freshMarker), findsOneWidget);
    expect(find.textContaining('최근 상태 확인:'), findsOneWidget);
  });

  testWidgets('ChatPanel rejects stale memory returned by the loader', (
    tester,
  ) async {
    const staleMarker = 'STALE_LOADED_CONDITION_MARKER';

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPanel(
          plantId: 'plant-1',
          plantName: '초록이',
          initialPlantMessage: '',
          waterDay: 0,
          fetchLatestConditionMemory: (_) async {
            return const LatestConditionMemory(
              message: staleMarker,
              eventType: 'normal',
              checkedAt: DateTime.utc(2026, 7, 1),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(staleMarker), findsNothing);
    expect(find.textContaining('최근 상태 확인:'), findsNothing);
  });

  testWidgets('ChatPanel keeps an immediate timestamp-free result visible', (
    tester,
  ) async {
    const immediateMarker = 'IMMEDIATE_CONDITION_MARKER';

    await tester.pumpWidget(
      const MaterialApp(
        home: ChatPanel(
          plantName: '초록이',
          initialPlantMessage: '',
          waterDay: 0,
          initialConditionMemory: LatestConditionMemory(
            message: immediateMarker,
            eventType: 'normal',
          ),
        ),
      ),
    );

    expect(find.textContaining(immediateMarker), findsOneWidget);
    expect(find.textContaining('최근 상태 확인:'), findsOneWidget);
  });
}
