import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plantalk2/app/plant_registration_action_coordinator.dart';
import 'package:plantalk2/photo/mock_plant_photo_analysis.dart';
import 'package:plantalk2/photo/supported_species.dart';
import 'package:plantalk2/plant_identification/adapters/plant_identification_adapter.dart';
import 'package:plantalk2/plant_identification/models/plant_identification_input.dart';
import 'package:plantalk2/plant_identification/models/plant_identification_result.dart';

void main() {
  testWidgets(
    'falls back to mock candidates when primary identification never completes',
    (tester) async {
      final coordinator = PlantRegistrationActionCoordinator(
        firstRegistrationAdapter: _NeverCompletingPlantIdentificationAdapter(),
        primaryIdentificationTimeout: const Duration(milliseconds: 5),
      );
      final image = XFile.fromData(
        Uint8List.fromList(const [1, 2, 3]),
        name: 'registration.jpg',
      );

      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final registrationFuture = coordinator.startNewPlantCreation(
        context: context,
        image: image,
        analysis: const MockPlantPhotoAnalysis(
          speciesSuggestions: [unknownSpecies],
          note: 'test',
        ),
        isMounted: () => true,
        onAddPlantToSupabase:
            (
              _, {
              required speciesKey,
              required speciesDisplayName,
              speciesGuess,
            }) {
              fail('plant insertion should not run before candidate selection');
            },
        onSaveRepresentativePlantPhoto: ({required image, plantId}) {
          fail('photo save should not run before candidate selection');
        },
        onAppendNewPlant: (_) {
          fail('plant append should not run before candidate selection');
        },
        onOpenFirstChatForNewPlant: (_, _, _) {
          fail('chat opening should not run before candidate selection');
        },
      );

      await tester.pump();
      expect(find.text('식물을 확인하는 중이에요'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('식물 종류 후보'), findsOneWidget);
      expect(find.text('스킨답서스'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      await registrationFuture;
    },
  );
}

class _NeverCompletingPlantIdentificationAdapter
    implements PlantIdentificationAdapter {
  @override
  String get providerKey => 'never_completes';

  @override
  Future<PlantIdentificationResult> identify(PlantIdentificationInput input) {
    return Completer<PlantIdentificationResult>().future;
  }
}
