import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../photo/existing_plant_match_dialog.dart';
import '../photo/mock_plant_photo_analysis.dart';
import '../photo/photo_input_service.dart';
import '../photo/photo_source_picker.dart';
import '../photo/plant_registration_preview.dart';
import '../photo/species_selection_dialog.dart';
import '../photo/supported_species.dart';
import '../widgets/add_plant_dialog.dart';

typedef AddPlantToSupabaseCallback =
    Future<Map<String, dynamic>> Function(
      String plantName, {
      required String speciesKey,
      required String speciesDisplayName,
      String? speciesGuess,
    });
typedef SaveRepresentativePlantPhotoCallback =
    Future<String> Function({required XFile image, String? plantId});
typedef AppendNewPlantCallback = void Function(Map<String, dynamic> newPlant);
typedef OpenFirstChatForNewPlantCallback =
    Future<void> Function(
      BuildContext context,
      Map<String, dynamic> newPlant,
      String firstMessage,
    );

class PlantRegistrationActionCoordinator {
  const PlantRegistrationActionCoordinator();

  Future<void> startPlantRegistration({
    required BuildContext context,
    required List<Map<String, dynamic>> extraPlants,
    required PhotoInputService photoInputService,
    required Future<void> Function(
      BuildContext context,
      XFile image,
      Map<String, dynamic> plant,
    )
    onAttachPhotoToExistingPlant,
    required Future<void> Function(
      BuildContext context,
      XFile image,
      MockPlantPhotoAnalysis analysis,
    )
    onStartNewPlantCreation,
  }) async {
    final source = await showPhotoSourcePicker(context);
    if (source == null) return;

    final image = await photoInputService.pickImage(source);

    if (image == null) return;
    if (!context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 200));

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return plantRegistrationPreviewContent(
          photoPath: image.path,
          onCancel: () {
            Navigator.pop(context);
          },
          onContinue: () async {
            Navigator.pop(context);
            await continuePlantRegistrationAfterPreview(
              context: context,
              image: image,
              extraPlants: extraPlants,
              onAttachPhotoToExistingPlant: onAttachPhotoToExistingPlant,
              onStartNewPlantCreation: onStartNewPlantCreation,
            );
          },
        );
      },
    );
  }

  Future<void> continuePlantRegistrationAfterPreview({
    required BuildContext context,
    required XFile image,
    required List<Map<String, dynamic>> extraPlants,
    required Future<void> Function(
      BuildContext context,
      XFile image,
      Map<String, dynamic> plant,
    )
    onAttachPhotoToExistingPlant,
    required Future<void> Function(
      BuildContext context,
      XFile image,
      MockPlantPhotoAnalysis analysis,
    )
    onStartNewPlantCreation,
  }) async {
    final analysis = mockAnalyzePlantPhoto(image.path);

    if (extraPlants.isNotEmpty) {
      final matchResult = await showExistingPlantMatchDialog(
        context,
        plants: List<Map<String, dynamic>>.from(extraPlants),
        analysis: analysis,
      );

      if (!context.mounted) return;
      if (matchResult == null) return;

      final existingPlant = matchResult.plant;
      if (!matchResult.createNewPlant && existingPlant != null) {
        await onAttachPhotoToExistingPlant(context, image, existingPlant);
        return;
      }
    }

    if (!context.mounted) return;

    await onStartNewPlantCreation(context, image, analysis);
  }

  Future<void> startNewPlantCreation({
    required BuildContext context,
    required XFile image,
    required MockPlantPhotoAnalysis analysis,
    required bool Function() isMounted,
    required AddPlantToSupabaseCallback onAddPlantToSupabase,
    required SaveRepresentativePlantPhotoCallback
    onSaveRepresentativePlantPhoto,
    required AppendNewPlantCallback onAppendNewPlant,
    required OpenFirstChatForNewPlantCallback onOpenFirstChatForNewPlant,
  }) async {
    final selectedSpecies = await showSpeciesSelectionDialog(
      context,
      suggestedSpecies: analysis.speciesSuggestions,
    );

    if (selectedSpecies == null || !context.mounted) return;

    addPlantDialog(
      context,
      image,
      selectedSpecies: selectedSpecies,
      speciesGuess: analysis.speciesSuggestions
          .map((species) => species.displayName)
          .join(', '),
      isMounted: isMounted,
      onAddPlantToSupabase: onAddPlantToSupabase,
      onSaveRepresentativePlantPhoto: onSaveRepresentativePlantPhoto,
      onAppendNewPlant: onAppendNewPlant,
      onOpenFirstChatForNewPlant: onOpenFirstChatForNewPlant,
    );
  }

  void addPlantDialog(
    BuildContext context,
    XFile image, {
    required SupportedSpecies selectedSpecies,
    required String speciesGuess,
    required bool Function() isMounted,
    required AddPlantToSupabaseCallback onAddPlantToSupabase,
    required SaveRepresentativePlantPhotoCallback
    onSaveRepresentativePlantPhoto,
    required AppendNewPlantCallback onAppendNewPlant,
    required OpenFirstChatForNewPlantCallback onOpenFirstChatForNewPlant,
  }) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return addPlantDialogContent(
          controller: controller,
          onCancel: () {
            Navigator.pop(context);
          },
          onAdd: () async {
            final plantName = controller.text.trim();
            if (plantName.isEmpty) return;

            final insertedPlant = await onAddPlantToSupabase(
              plantName,
              speciesKey: selectedSpecies.key,
              speciesDisplayName: selectedSpecies.displayName,
              speciesGuess: speciesGuess,
            );

            if (!isMounted()) return;

            const firstMessage = '너를 기다리고 있었다.';

            final plantId = insertedPlant['id']?.toString();
            final photoPath = await onSaveRepresentativePlantPhoto(
              image: image,
              plantId: plantId,
            );

            final newPlant = <String, dynamic>{
              'id': insertedPlant['id'],
              'name': insertedPlant['name'] ?? plantName,
              'message': firstMessage,
              'waterDay': insertedPlant['water_day'] ?? 0,
              'friendship': insertedPlant['friendship'] ?? 0,
              'photoPath': photoPath,
              'speciesKey': insertedPlant['species_key'] ?? selectedSpecies.key,
              'speciesDisplayName':
                  insertedPlant['species_display_name'] ??
                  selectedSpecies.displayName,
              'speciesGuess': insertedPlant['species_guess'] ?? speciesGuess,
              'mood': insertedPlant['mood'] ?? '보통',
            };

            onAppendNewPlant(newPlant);

            if (!context.mounted) return;

            Navigator.pop(context);

            await onOpenFirstChatForNewPlant(context, newPlant, firstMessage);
          },
        );
      },
    );
  }
}
