import 'package:flutter/material.dart';

import '../photo/photo_input_service.dart';
import '../photo/photo_source_picker.dart';
import '../services/deep_health_assessment_flow_service.dart';
import 'plant_card_state_mapper.dart';

class DeepHealthAssessmentActionCoordinator {
  const DeepHealthAssessmentActionCoordinator();

  Future<DeepHealthAssessmentFlowOutcome?> handleAssessment({
    required BuildContext context,
    required Map<String, dynamic> plant,
    required PhotoInputService photoInputService,
    required DeepHealthAssessmentFlowService flowService,
  }) async {
    final plantId = plantIdOf(plant);
    if (plantId == null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식물 id가 없어 심층 진단을 시작할 수 없어요.')),
      );
      return null;
    }

    final source = await showPhotoSourcePicker(context);
    if (source == null) return null;

    final image = await photoInputService.pickImage(source);
    if (image == null) return null;

    late final DeepHealthAssessmentFlowOutcome outcome;
    try {
      outcome = await flowService.assess(
        image: image,
        plantId: plantId,
        speciesKey: plant['speciesKey']?.toString(),
        speciesDisplayName: plant['speciesDisplayName']?.toString(),
      );
    } catch (error) {
      if (!context.mounted) return null;

      debugPrint('Deep health assessment failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('심층 진단에 실패했어요. 잠시 후 다시 시도해 주세요.'),
        ),
      );
      return null;
    }

    if (!context.mounted) return null;

    if (outcome is DeepHealthAssessmentBlockedOutcome) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(outcome.access.title),
            content: Text(
              outcome.access.message + '\n\n결제 기능은 준비 중이에요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return outcome;
    }

    final completed = outcome as DeepHealthAssessmentCompletedOutcome;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('심층 건강 분석'),
          content: Text(
            completed.analysisResult.conditionMessage +
                '\n\n사진 기반 참고 결과이므로 잎·흙 상태를 함께 확인해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    return completed;
  }
}
