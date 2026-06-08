import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../photo/existing_plant_match_dialog.dart';
import '../photo/mock_plant_photo_analysis.dart';
import '../photo/photo_input_service.dart';
import '../photo/photo_source_picker.dart';
import '../photo/plant_registration_preview.dart';

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
}
