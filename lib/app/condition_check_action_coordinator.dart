import 'package:flutter/material.dart';

import '../photo/photo_input_service.dart';
import '../photo/photo_source_picker.dart';
import '../services/plant_condition_check_flow_service.dart';
import 'plant_card_state_mapper.dart';

class ConditionCheckActionCoordinator {
  const ConditionCheckActionCoordinator();

  Future<void> handleConditionCheck({
    required BuildContext context,
    required Map<String, dynamic> plant,
    required PhotoInputService photoInputService,
    required PlantConditionCheckFlowService plantConditionCheckFlowService,
  }) async {
    final plantId = plantIdOf(plant);
    if (plantId == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('식물 id가 없어 상태 확인할 수 없어요')));
      return;
    }

    final source = await showPhotoSourcePicker(context);
    if (source == null) return;

    final image = await photoInputService.pickImage(source);
    if (image == null) return;

    final result = await plantConditionCheckFlowService.checkCondition(
      image: image,
      plantId: plantId,
      speciesKey: plant['speciesKey']?.toString(),
      speciesDisplayName: plant['speciesDisplayName']?.toString(),
    );

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('상태 확인'),
          content: Text(result.analysisResult.conditionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}
