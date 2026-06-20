import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_identification/models/plant_identification_candidate.dart';
import 'package:plantalk2/plant_identification/widgets/plant_identification_candidate_list.dart';

void main() {
  testWidgets(
    'shows Korean candidate title and keeps original selection object',
    (tester) async {
      final candidate = PlantIdentificationCandidate(
        displayName: 'pothos',
        scientificName: 'Epipremnum aureum',
        commonNames: const ['pothos'],
        confidence: 0.72,
        source: 'plantnet',
        candidateRank: 1,
      );

      final events = await _pumpCandidateList(tester, [candidate]);

      expect(find.text('가장 비슷한 후보예요'), findsOneWidget);
      expect(find.text('사진과 비슷한 식물을 확인해 주세요.'), findsOneWidget);
      expect(find.text('스킨답서스'), findsOneWidget);
      expect(find.textContaining('Epipremnum aureum'), findsOneWidget);
      expect(find.textContaining('신뢰도 72%'), findsOneWidget);
      expect(
        find.textContaining(_unregisteredKoreanNameMessage),
        findsNothing,
      );
      expect(find.textContaining(_lowConfidenceMessage), findsNothing);

      await tester.tap(find.text('스킨답서스'));
      await tester.pump();

      expect(events.selectedCandidate, same(candidate));
      expect(events.manualEntryTapped, isFalse);
    },
  );

  testWidgets(
    'shows English title and unregistered message for catalog misses',
    (tester) async {
      final candidate = PlantIdentificationCandidate(
        displayName: 'common garden petunia',
        scientificName: 'Petunia atkinsiana',
        commonNames: const ['garden petunia'],
        confidence: 0.72,
        source: 'plantnet',
        candidateRank: 1,
      );

      await _pumpCandidateList(tester, [candidate]);

      expect(find.text('common garden petunia'), findsOneWidget);
      expect(find.textContaining('Petunia atkinsiana'), findsOneWidget);
      expect(
        find.textContaining(_unregisteredKoreanNameMessage),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows cautious message only for low confidence', (tester) async {
    final lowConfidenceCandidate = PlantIdentificationCandidate(
      displayName: 'common garden petunia',
      scientificName: 'Petunia atkinsiana',
      confidence: 0.49,
      source: 'plantnet',
      candidateRank: 1,
    );

    await _pumpCandidateList(tester, [lowConfidenceCandidate]);

    expect(find.textContaining(_lowConfidenceMessage), findsOneWidget);
  });

  testWidgets(
    'does not show low confidence message for sufficient or null confidence',
    (tester) async {
      final sufficientConfidenceCandidate = PlantIdentificationCandidate(
        displayName: 'common garden petunia',
        scientificName: 'Petunia atkinsiana',
        confidence: 0.72,
        source: 'plantnet',
        candidateRank: 1,
      );
      final nullConfidenceCandidate = PlantIdentificationCandidate(
        displayName: 'unknown flower',
        scientificName: 'Unknown flower',
        source: 'plantnet',
        candidateRank: 2,
      );

      await _pumpCandidateList(tester, [
        sufficientConfidenceCandidate,
        nullConfidenceCandidate,
      ]);

      expect(find.textContaining(_lowConfidenceMessage), findsNothing);
    },
  );

  testWidgets('manual entry callback still works', (tester) async {
    final candidate = PlantIdentificationCandidate(
      displayName: 'pothos',
      scientificName: 'Epipremnum aureum',
      commonNames: const ['pothos'],
      confidence: 0.72,
      source: 'plantnet',
      candidateRank: 1,
    );

    final events = await _pumpCandidateList(tester, [candidate]);

    await tester.tap(find.text('직접 입력'));
    await tester.pump();

    expect(events.selectedCandidate, isNull);
    expect(events.manualEntryTapped, isTrue);
  });
}

const _unregisteredKoreanNameMessage = '아직 한국어 이름이 등록되지 않은 후보예요.';
const _lowConfidenceMessage = '사진만으로는 확신이 낮아요. 가장 비슷한 후보를 보여드릴게요.';

Future<_CandidateListEvents> _pumpCandidateList(
  WidgetTester tester,
  List<PlantIdentificationCandidate> candidates,
) async {
  final events = _CandidateListEvents();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PlantIdentificationCandidateList(
          candidates: candidates,
          onCandidateSelected: (selected) {
            events.selectedCandidate = selected;
          },
          onManualEntry: () {
            events.manualEntryTapped = true;
          },
        ),
      ),
    ),
  );

  return events;
}

class _CandidateListEvents {
  PlantIdentificationCandidate? selectedCandidate;
  bool manualEntryTapped = false;
}
