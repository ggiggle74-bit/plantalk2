import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/chat_panel.dart';
import 'package:plantalk2/models/latest_condition_memory.dart';

void main() {
  testWidgets('chat panel does not overflow when the keyboard is visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(360, 800),
            devicePixelRatio: 3,
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
          child: ChatPanel(
            plantName: '뜨뜨',
            speciesDisplayName: '스킨답서스',
            initialPlantMessage: '오늘은 어떤 이야기를 해볼까?',
            waterDay: 0,
            initialConditionMemory: LatestConditionMemory(
              message: '사진을 확인했어요. 지금은 큰 이상이 없어 보여요.',
              eventType: 'normal',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}
