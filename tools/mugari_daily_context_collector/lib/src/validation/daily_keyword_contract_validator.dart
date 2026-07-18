import '../models/daily_keyword_candidate.dart';
import '../models/daily_keyword_context_document.dart';

final class DailyKeywordContractValidationResult {
  DailyKeywordContractValidationResult(Iterable<String> errors)
    : errors = List.unmodifiable(errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;

  void throwIfInvalid() {
    if (!isValid) {
      throw FormatException(errors.join('\n'));
    }
  }
}

final class DailyKeywordContractValidator {
  const DailyKeywordContractValidator({
    this.minimumFitScore = 0.60,
    this.maximumKeywords = 8,
    this.maximumConversationAngles = 4,
    this.maximumTargetAgeBands = 6,
  });

  final double minimumFitScore;
  final int maximumKeywords;
  final int maximumConversationAngles;
  final int maximumTargetAgeBands;

  DailyKeywordContractValidationResult validate(
    DailyKeywordContextDocument document,
  ) {
    final errors = <String>[];

    if (document.schemaVersion !=
        DailyKeywordContextDocument.currentSchemaVersion) {
      errors.add(
        'schemaVersion must be '
        '${DailyKeywordContextDocument.currentSchemaVersion}.',
      );
    }
    _validateText(
      errors,
      label: 'locale',
      value: document.locale,
      maximumLength: 32,
    );
    _validateText(
      errors,
      label: 'regionCode',
      value: document.regionCode,
      maximumLength: 120,
    );
    _validateText(
      errors,
      label: 'sourceVersion',
      value: document.sourceVersion,
      maximumLength: 64,
    );

    if (document.keywords.length > maximumKeywords) {
      errors.add('keywords must contain at most $maximumKeywords candidates.');
    }

    final candidateKeys = <String>{};
    for (var index = 0; index < document.keywords.length; index++) {
      final candidate = document.keywords[index];
      final prefix = 'keywords[$index]';
      _validateCandidate(errors, candidate, prefix);

      final candidateKey =
          '${_normalize(candidate.type)}|${_normalize(candidate.keyword)}';
      if (!candidateKeys.add(candidateKey)) {
        errors.add('$prefix duplicates an earlier type and keyword.');
      }
    }

    return DailyKeywordContractValidationResult(errors);
  }

  void _validateCandidate(
    List<String> errors,
    DailyKeywordCandidate candidate,
    String prefix,
  ) {
    if (!DailyKeywordTypes.allowed.contains(candidate.type)) {
      errors.add('$prefix.type is not supported: ${candidate.type}.');
    }
    if (!DailyKeywordTones.allowed.contains(candidate.tone)) {
      errors.add('$prefix.tone is not supported: ${candidate.tone}.');
    }

    _validateText(
      errors,
      label: '$prefix.keyword',
      value: candidate.keyword,
      maximumLength: 40,
    );
    _validateText(
      errors,
      label: '$prefix.hint',
      value: candidate.hint,
      maximumLength: 160,
    );
    _validateText(
      errors,
      label: '$prefix.plantHint',
      value: candidate.plantHint,
      maximumLength: 160,
    );

    final category = candidate.category;
    if (category != null) {
      _validateText(
        errors,
        label: '$prefix.category',
        value: category,
        maximumLength: 64,
      );
    }

    if (!candidate.fitScore.isFinite ||
        candidate.fitScore < minimumFitScore ||
        candidate.fitScore > 1.0) {
      errors.add(
        '$prefix.fitScore must be finite and between '
        '$minimumFitScore and 1.0.',
      );
    }

    final relevanceScore = candidate.relevanceScore;
    if (relevanceScore != null &&
        (!relevanceScore.isFinite ||
            relevanceScore < 0.0 ||
            relevanceScore > 1.0)) {
      errors.add('$prefix.relevanceScore must be between 0.0 and 1.0.');
    }

    _validateTargetAgeBands(errors, candidate, prefix);

    if (candidate.conversationAngles.isEmpty) {
      errors.add('$prefix.conversationAngles must not be empty.');
    }
    if (candidate.conversationAngles.length > maximumConversationAngles) {
      errors.add(
        '$prefix.conversationAngles must contain at most '
        '$maximumConversationAngles items.',
      );
    }

    final angleKeys = <String>{};
    for (
      var angleIndex = 0;
      angleIndex < candidate.conversationAngles.length;
      angleIndex++
    ) {
      final angle = candidate.conversationAngles[angleIndex];
      _validateText(
        errors,
        label: '$prefix.conversationAngles[$angleIndex]',
        value: angle,
        maximumLength: 120,
      );
      if (!angleKeys.add(_normalize(angle))) {
        errors.add(
          '$prefix.conversationAngles[$angleIndex] duplicates an earlier angle.',
        );
      }
    }
  }

  void _validateTargetAgeBands(
    List<String> errors,
    DailyKeywordCandidate candidate,
    String prefix,
  ) {
    final ageBands = candidate.targetAgeBands;
    if (ageBands.length > maximumTargetAgeBands) {
      errors.add(
        '$prefix.targetAgeBands must contain at most '
        '$maximumTargetAgeBands items.',
      );
    }

    final seen = <String>{};
    for (var index = 0; index < ageBands.length; index++) {
      final ageBand = ageBands[index];
      final label = '$prefix.targetAgeBands[$index]';
      if (!DailyKeywordAgeBands.allowed.contains(ageBand)) {
        errors.add('$label is not supported: $ageBand.');
      }
      if (!seen.add(_normalize(ageBand))) {
        errors.add('$label duplicates an earlier age band.');
      }
    }
  }

  void _validateText(
    List<String> errors, {
    required String label,
    required String value,
    required int maximumLength,
  }) {
    if (value.trim().isEmpty) {
      errors.add('$label must not be empty.');
      return;
    }
    if (value.length > maximumLength) {
      errors.add('$label must be at most $maximumLength characters.');
    }
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
