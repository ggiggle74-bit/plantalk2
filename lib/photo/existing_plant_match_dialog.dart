import 'package:flutter/material.dart';

import 'mock_plant_photo_analysis.dart';

class ExistingPlantMatchResult {
  final Map<String, dynamic>? plant;
  final bool createNewPlant;

  const ExistingPlantMatchResult._({
    required this.plant,
    required this.createNewPlant,
  });

  const ExistingPlantMatchResult.existing(Map<String, dynamic> plant)
      : this._(plant: plant, createNewPlant: false);

  const ExistingPlantMatchResult.createNew()
      : this._(plant: null, createNewPlant: true);
}

Future<ExistingPlantMatchResult?> showExistingPlantMatchDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> plants,
  required MockPlantPhotoAnalysis analysis,
}) {
  return showDialog<ExistingPlantMatchResult>(
    context: context,
    builder: (dialogContext) {
      final suggestions = analysis.speciesSuggestions
          .map((species) => species.displayName)
          .join(', ');

      return AlertDialog(
        title: const Text('기존 식물인지 확인'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (suggestions.isNotEmpty) ...[
                Text('사진 분석 후보: $suggestions'),
                const SizedBox(height: 6),
              ],
              Text(analysis.note),
              const SizedBox(height: 12),
              const Text('이미 등록한 식물이라면 아래에서 선택해 주세요.'),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    final name = plant['name']?.toString() ?? '이름 없는 식물';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name),
                      subtitle: const Text('기존 식물이에요'),
                      onTap: () {
                        Navigator.pop(
                          dialogContext,
                          ExistingPlantMatchResult.existing(plant),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                const ExistingPlantMatchResult.createNew(),
              );
            },
            child: const Text('다른 식물이에요 / 새 식물로 등록'),
          ),
        ],
      );
    },
  );
}
