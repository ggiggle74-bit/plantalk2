import 'package:flutter/material.dart';

import '../photo/photo_input_service.dart';
import '../photo/photo_source_picker.dart';
import '../services/plant_condition_check_flow_service.dart';
import 'plant_card_state_mapper.dart';

class ConditionCheckActionCoordinator {
  const ConditionCheckActionCoordinator();

  Future<PlantConditionCheckFlowResult?> handleConditionCheck({
    required BuildContext context,
    required Map<String, dynamic> plant,
    required PhotoInputService photoInputService,
    required PlantConditionCheckFlowService plantConditionCheckFlowService,
  }) async {
    final plantId = plantIdOf(plant);
    if (plantId == null) {
      if (!context.mounted) return null;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('식물 id가 없어 상태 확인할 수 없어요')));
      return null;
    }

    final source = await showPhotoSourcePicker(context);
    if (source == null) return null;

    final image = await photoInputService.pickImage(source);
    if (image == null) return null;

    late final PlantConditionCheckFlowResult result;
    try {
      result = await plantConditionCheckFlowService.checkCondition(
        image: image,
        plantId: plantId,
        speciesKey: plant['speciesKey']?.toString(),
        speciesDisplayName: plant['speciesDisplayName']?.toString(),
      );
    } catch (error) {
      if (!context.mounted) return null;

      debugPrint('Condition check failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상태 확인에 실패했어요. 다시 시도해 주세요.')),
      );
      return null;
    }

    if (!context.mounted) return null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('상태 확인'),
          content: Text(result.analysisResult.conditionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    return result;
  }
}
