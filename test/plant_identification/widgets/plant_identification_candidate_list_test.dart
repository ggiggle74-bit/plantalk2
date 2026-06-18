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

      PlantIdentificationCandidate? selectedCandidate;
      var manualEntryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlantIdentificationCandidateList(
              candidates: [candidate],
              onCandidateSelected: (selected) {
                selectedCandidate = selected;
              },
              onManualEntry: () {
                manualEntryTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('스킨답서스'), findsOneWidget);
      expect(find.textContaining('Epipremnum aureum'), findsOneWidget);
      expect(find.textContaining('72%'), findsOneWidget);

      await tester.tap(find.text('스킨답서스'));
      await tester.pump();

      expect(selectedCandidate, same(candidate));
      expect(manualEntryTapped, isFalse);

      await tester.tap(find.text('직접 입력'));
      await tester.pump();

      expect(manualEntryTapped, isTrue);
    },
  );
}
