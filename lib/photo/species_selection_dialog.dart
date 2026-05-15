import 'package:flutter/material.dart';

import 'supported_species.dart';

Future<SupportedSpecies?> showSpeciesSelectionDialog(
  BuildContext context, {
  required List<SupportedSpecies> suggestedSpecies,
}) {
  final controller = TextEditingController();
  var candidates = suggestedSpecies.isNotEmpty
      ? suggestedSpecies
      : searchSupportedSpecies('');

  return showDialog<SupportedSpecies>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          void updateCandidates(String value) {
            final matches = searchSupportedSpecies(value);
            setDialogState(() {
              candidates = matches;
            });
          }

          return AlertDialog(
            title: const Text('식물 종류 선택'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: '예: 몬스, 스투키, 선인장',
                      labelText: '식물 종류 검색',
                    ),
                    onChanged: updateCandidates,
                  ),
                  const SizedBox(height: 12),
                  if (candidates.isEmpty)
                    const Text('지금 후보가 없으면 알 수 없음으로 안전하게 등록합니다.')
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final species = candidates[index];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(species.displayName),
                            subtitle: Text(species.key),
                            onTap: () {
                              Navigator.pop(dialogContext, species);
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
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, unknownSpecies),
                child: const Text('알 수 없음으로 등록'),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}
