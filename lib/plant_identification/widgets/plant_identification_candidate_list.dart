import 'package:flutter/material.dart';

import '../models/plant_identification_candidate.dart';

class PlantIdentificationCandidateList extends StatelessWidget {
  const PlantIdentificationCandidateList({
    super.key,
    required this.candidates,
    required this.onCandidateSelected,
    required this.onManualEntry,
    this.selectedCandidate,
  });

  final List<PlantIdentificationCandidate> candidates;
  final PlantIdentificationCandidate? selectedCandidate;
  final ValueChanged<PlantIdentificationCandidate> onCandidateSelected;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (candidates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '식물 후보를 찾지 못했어요. 직접 입력해 주세요.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ...candidates.map((candidate) {
            final isSelected = identical(candidate, selectedCandidate);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  selected: isSelected,
                  title: Text(candidate.displayName),
                  subtitle: _CandidateDetails(candidate: candidate),
                  trailing: Text('#${candidate.candidateRank}'),
                  onTap: () => onCandidateSelected(candidate),
                ),
              ),
            );
          }),
        OutlinedButton(onPressed: onManualEntry, child: const Text('직접 입력')),
      ],
    );
  }
}

class _CandidateDetails extends StatelessWidget {
  const _CandidateDetails({required this.candidate});

  final PlantIdentificationCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (_hasText(candidate.scientificName)) candidate.scientificName!.trim(),
      if (candidate.commonNames.isNotEmpty)
        candidate.commonNames
            .where(_hasText)
            .map((name) => name.trim())
            .join(', '),
      if (candidate.confidence != null)
        '신뢰도 ${_formatConfidence(candidate.confidence!)}',
    ].where(_hasText).toList(growable: false);

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(details.join('\n'));
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String _formatConfidence(double confidence) {
    final percent = (confidence * 100).round();
    return '$percent%';
  }
}
