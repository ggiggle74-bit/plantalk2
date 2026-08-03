import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/widgets/plant_card.dart';

void main() {
  testWidgets('sample card explains that health actions require registration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: plantCard(
            '몬스테라',
            '목이 조금 말라요 🌱',
            3,
            0,
            () {},
            isSamplePlant: true,
          ),
        ),
      ),
    );

    expect(
      find.text(
        '예시 식물이에요. 내 식물을 등록하면 상태 확인과 심층 진단을 이용할 수 있어요.',
      ),
      findsOneWidget,
    );
    expect(find.text('상태 확인'), findsNothing);
    expect(find.text('🔎 심층 진단'), findsNothing);
  });

  testWidgets('registered card keeps condition and deep health actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: plantCard(
            '내 몬스테라',
            '오늘은 괜찮아요.',
            1,
            3,
            () {},
            onConditionCheck: () {},
            onDeepHealthAssessment: () {},
          ),
        ),
      ),
    );

    expect(
      find.text(
        '예시 식물이에요. 내 식물을 등록하면 상태 확인과 심층 진단을 이용할 수 있어요.',
      ),
      findsNothing,
    );
    expect(find.text('상태 확인'), findsOneWidget);
    expect(find.text('🔎 심층 진단'), findsOneWidget);
  });
}
