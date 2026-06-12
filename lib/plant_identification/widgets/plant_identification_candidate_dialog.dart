import 'package:flutter/material.dart';

import '../models/plant_identification_candidate.dart';
import 'plant_identification_candidate_list.dart';

class PlantIdentificationCandidateDialogResult {
  const PlantIdentificationCandidateDialogResult._({
    required this.isManualEntry,
    this.candidate,
  });

  const PlantIdentificationCandidateDialogResult.selected(
    PlantIdentificationCandidate candidate,
  ) : this._(isManualEntry: false, candidate: candidate);

  const PlantIdentificationCandidateDialogResult.manualEntry()
    : this._(isManualEntry: true);

  final bool isManualEntry;
  final PlantIdentificationCandidate? candidate;
}

Future<PlantIdentificationCandidateDialogResult?>
showPlantIdentificationCandidateDialog(
  BuildContext context, {
  required List<PlantIdentificationCandidate> candidates,
}) {
  PlantIdentificationCandidate? selectedCandidate;

  return showDialog<PlantIdentificationCandidateDialogResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('식물 종류 후보'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('사진으로 추정한 후보예요. 아직 식물 종류가 확정된 것은 아니에요.'),
                    const SizedBox(height: 12),
                    PlantIdentificationCandidateList(
                      candidates: candidates,
                      selectedCandidate: selectedCandidate,
                      onCandidateSelected: (candidate) {
                        setDialogState(() {
                          selectedCandidate = candidate;
                        });
                      },
                      onManualEntry: () {
                        Navigator.pop(
                          dialogContext,
                          const PlantIdentificationCandidateDialogResult.manualEntry(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: selectedCandidate == null
                    ? null
                    : () {
                        Navigator.pop(
                          dialogContext,
                          PlantIdentificationCandidateDialogResult.selected(
                            selectedCandidate!,
                          ),
                        );
                      },
                child: const Text('이 후보로 계속'),
              ),
            ],
          );
        },
      );
    },
  );
}
