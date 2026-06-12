import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../plant_identification/adapters/mock_plant_identification_adapter.dart';
import '../plant_identification/models/plant_identification_candidate.dart';
import '../plant_identification/models/plant_identification_input.dart';
import '../plant_identification/services/plant_identification_service.dart';
import '../plant_identification/widgets/plant_identification_candidate_dialog.dart';
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
    final identificationResult =
        await const PlantIdentificationService(
          adapter: MockPlantIdentificationAdapter(),
        ).identify(
          PlantIdentificationInput(
            imageUrl: image.path,
            locale: 'ko',
            requestedAt: DateTime.now(),
            source: 'first_registration',
          ),
        );

    if (!context.mounted) return;

    final candidateDialogResult = await showPlantIdentificationCandidateDialog(
      context,
      candidates: identificationResult.candidates,
    );

    if (candidateDialogResult == null || !context.mounted) return;

    final suggestedSpecies = _speciesSuggestionsForIdentificationResult(
      candidateDialogResult,
      analysis.speciesSuggestions,
    );

    final selectedSpecies = await showSpeciesSelectionDialog(
      context,
      suggestedSpecies: suggestedSpecies,
    );

    if (selectedSpecies == null || !context.mounted) return;

    addPlantDialog(
      context,
      image,
      selectedSpecies: selectedSpecies,
      speciesGuess: suggestedSpecies
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

  List<SupportedSpecies> _speciesSuggestionsForIdentificationResult(
    PlantIdentificationCandidateDialogResult dialogResult,
    List<SupportedSpecies> fallbackSuggestions,
  ) {
    final selectedCandidate = dialogResult.candidate;
    if (dialogResult.isManualEntry || selectedCandidate == null) {
      return fallbackSuggestions;
    }

    final candidateSpecies = _supportedSpeciesFromCandidate(selectedCandidate);
    return [
      candidateSpecies,
      ...fallbackSuggestions.where(
        (species) =>
            species.key != candidateSpecies.key &&
            species.displayName != candidateSpecies.displayName,
      ),
    ];
  }

  SupportedSpecies _supportedSpeciesFromCandidate(
    PlantIdentificationCandidate candidate,
  ) {
    return SupportedSpecies(
      key: _candidateSpeciesKey(candidate),
      displayName: candidate.displayName.trim(),
      aliases: [
        if (_hasText(candidate.scientificName))
          candidate.scientificName!.trim(),
        ...candidate.commonNames
            .where(_hasText)
            .map((commonName) => commonName.trim()),
      ],
    );
  }

  String _candidateSpeciesKey(PlantIdentificationCandidate candidate) {
    final rawId = candidate.rawId?.trim();
    if (_hasText(rawId)) {
      return rawId!;
    }

    final scientificName = candidate.scientificName?.trim();
    if (_hasText(scientificName)) {
      return scientificName!.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    }

    return candidate.displayName.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
