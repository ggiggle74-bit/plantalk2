import 'package:flutter/material.dart';

import '../bridges/plant_identification_korean_name_bridge.dart';
import '../models/plant_identification_candidate.dart';

const double _lowConfidenceThreshold = 0.5;

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
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('가장 비슷한 후보예요', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '사진과 비슷한 식물을 확인해 주세요.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        if (candidates.isNotEmpty)
          ...candidates.map((candidate) {
            final isSelected = _isSelected(candidate, selectedCandidate);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  selected: isSelected,
                  title: Text(
                    displayNameFromPlantIdentificationCandidate(candidate),
                  ),
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

  static bool _isSelected(
    PlantIdentificationCandidate candidate,
    PlantIdentificationCandidate? selectedCandidate,
  ) {
    if (selectedCandidate == null) {
      return false;
    }
    if (identical(candidate, selectedCandidate)) {
      return true;
    }

    final rawId = candidate.rawId?.trim();
    final selectedRawId = selectedCandidate.rawId?.trim();
    if (_hasText(rawId) && _hasText(selectedRawId)) {
      return candidate.source == selectedCandidate.source &&
          rawId == selectedRawId;
    }

    return candidate.source == selectedCandidate.source &&
        candidate.candidateRank == selectedCandidate.candidateRank &&
        candidate.displayName == selectedCandidate.displayName;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _CandidateDetails extends StatelessWidget {
  const _CandidateDetails({required this.candidate});

  final PlantIdentificationCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final commonNames = candidate.commonNames
        .where(_hasText)
        .map((name) => name.trim())
        .toList(growable: false);
    final hasCatalogMatch =
        koreanNameEntryFromPlantIdentificationCandidate(candidate) != null;
    final details = <String>[
      if (_hasText(candidate.scientificName)) candidate.scientificName!.trim(),
      if (commonNames.isNotEmpty) commonNames.join(', '),
      if (candidate.confidence != null)
        '신뢰도 ${_formatConfidence(candidate.confidence!)}',
      if (!hasCatalogMatch) '아직 한국어 이름이 등록되지 않은 후보예요.',
      if (_isLowConfidence(candidate.confidence))
        '사진만으로는 확신이 낮아요. 가장 비슷한 후보를 보여드릴게요.',
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
    final percent = (confidence.clamp(0.0, 1.0) * 100).round();
    return '$percent%';
  }

  static bool _isLowConfidence(double? confidence) {
    return confidence != null && confidence < _lowConfidenceThreshold;
  }
}
