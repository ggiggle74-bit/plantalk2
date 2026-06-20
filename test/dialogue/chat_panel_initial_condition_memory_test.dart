import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel.dart';
import 'package:plantalk2/dialogue/condition_memory_dialogue_bridge.dart';
import 'package:plantalk2/dialogue/dialogue_engine.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';
import 'package:plantalk2/services/plant_condition_analysis_service.dart';

void main() {
  testWidgets('direct memory is available immediately', (tester) async {
    var latestMemoryCallCount = 0;
    final recordedRequests = <_DialogueReplyRequest>[];

    await _pumpChatPanel(
      tester,
      ChatPanel(
        plantId: 'plant-1',
        plantName: '초록이',
        initialPlantMessage: _uncertainMessage,
        waterDay: 0,
        initialConditionMemory: const LatestConditionMemory(
          message: _uncertainMessage,
          eventType: PlantConditionEventTypes.uncertain,
        ),
        fetchLatestConditionMemory: (plantId) async {
          latestMemoryCallCount++;
          return const LatestConditionMemory(
            message: _staleMemoryMessage,
            eventType: PlantConditionEventTypes.needsWater,
          );
        },
        fetchDialogueReply: ({situation, conditionKey}) async {
          recordedRequests.add(
            _DialogueReplyRequest(
              situation: situation,
              conditionKey: conditionKey,
            ),
          );
          return null;
        },
      ),
    );

    expect(find.textContaining('최근 상태 확인: $_uncertainMessage'), findsOneWidget);
    expect(latestMemoryCallCount, 0);

    await tester.enterText(find.byType(TextField), '상태 어때?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump();

    expect(recordedRequests, hasLength(1));
    expect(
      recordedRequests.single.situation,
      PhotoConditionDialogueSituations.conditionCheckFollowup,
    );
    expect(
      recordedRequests.single.conditionKey,
      ConditionMemoryDialogueBridge.conditionKeyGeneral,
    );
    expect(
      recordedRequests.map((request) => request.situation),
      isNot(contains(PhotoConditionDialogueSituations.conditionCheckRequest)),
    );
    expect(find.textContaining('최근 상태 확인에서는 확실히 판단하기 어려웠어.'), findsOneWidget);
    expect(find.textContaining(_uncertainMessage), findsWidgets);
    expect(find.textContaining(_staleMemoryMessage), findsNothing);
    expect(latestMemoryCallCount, 0);
  });

  testWidgets('existing DB fallback remains intact', (tester) async {
    var latestMemoryCallCount = 0;

    await _pumpChatPanel(
      tester,
      ChatPanel(
        plantId: 'plant-1',
        plantName: '초록이',
        initialPlantMessage: '',
        waterDay: 0,
        fetchLatestConditionMemory: (plantId) async {
          latestMemoryCallCount++;
          return const LatestConditionMemory(
            message: _loadedMemoryMessage,
            eventType: PlantConditionEventTypes.normal,
          );
        },
        fetchDialogueReply: ({situation, conditionKey}) async => null,
      ),
    );

    expect(latestMemoryCallCount, 1);

    await tester.pump();

    expect(
      find.textContaining('최근 상태 확인: $_loadedMemoryMessage'),
      findsOneWidget,
    );
  });

  testWidgets('direct memory works without DB eligibility', (tester) async {
    var latestMemoryCallCount = 0;

    await _pumpChatPanel(
      tester,
      ChatPanel(
        plantName: '초록이',
        initialPlantMessage: _uncertainMessage,
        waterDay: 0,
        initialConditionMemory: const LatestConditionMemory(
          message: _uncertainMessage,
          eventType: PlantConditionEventTypes.uncertain,
        ),
        fetchLatestConditionMemory: (plantId) async {
          latestMemoryCallCount++;
          return const LatestConditionMemory(
            message: _staleMemoryMessage,
            eventType: PlantConditionEventTypes.needsWater,
          );
        },
        fetchDialogueReply: ({situation, conditionKey}) async => null,
      ),
    );

    expect(find.textContaining('최근 상태 확인: $_uncertainMessage'), findsOneWidget);
    expect(latestMemoryCallCount, 0);
  });
}

Future<void> _pumpChatPanel(WidgetTester tester, ChatPanel chatPanel) {
  return tester.pumpWidget(MaterialApp(home: chatPanel));
}

class _DialogueReplyRequest {
  const _DialogueReplyRequest({
    required this.situation,
    required this.conditionKey,
  });

  final String? situation;
  final String? conditionKey;
}

const _uncertainMessage = '사진만으로는 상태를 확실히 판단하기 어려워요.';
const _staleMemoryMessage = '오래된 DB 상태예요.';
const _loadedMemoryMessage = '방금 불러온 DB 상태예요.';
