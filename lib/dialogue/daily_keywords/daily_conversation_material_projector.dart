import '../models/daily_keyword_context.dart';
import 'catalogs/blocked_keyword_catalog.dart';
import 'models/daily_conversation_material_context.dart';
import 'models/daily_keyword_candidate.dart';

class DailyConversationMaterialProjector {
  const DailyConversationMaterialProjector({
    this.minimumFitScore = 0.60,
    this.maximumMaterials = 8,
  }) : assert(minimumFitScore >= 0 && minimumFitScore <= 1),
       assert(maximumMaterials > 0 && maximumMaterials <= 8);

  final double minimumFitScore;
  final int maximumMaterials;

  DailyConversationMaterialContext? project({
    required DailyKeywordContext? context,
    required DateTime now,
  }) {
    if (context == null ||
        !context.hasKeywords ||
        !_isSameCalendarDate(context.date, now)) {
      return null;
    }

    final materials = <DailyConversationMaterial>[];
    final seenKeywords = <String>{};

    for (final entry in context.keywords) {
      final material = _projectEntry(entry);
      if (material == null) {
        continue;
      }

      final identity = material.keyword.toLowerCase();
      if (!seenKeywords.add(identity)) {
        continue;
      }

      materials.add(material);
      if (materials.length == maximumMaterials) {
        break;
      }
    }

    if (materials.isEmpty) {
      return null;
    }

    return DailyConversationMaterialContext(
      date: context.date,
      locale: context.locale,
      generatedAt: context.generatedAt,
      sourceVersion: context.sourceVersion,
      materials: materials,
    );
  }

  DailyConversationMaterial? _projectEntry(DailyKeywordEntry entry) {
    final type = entry.type.trim().toLowerCase();
    final keyword = entry.keyword.trim();
    final hint = entry.hint.trim();
    final plantHint = entry.plantHint?.trim();
    final tone = entry.tone?.trim().toLowerCase();
    final fitScore = entry.fitScore;
    final relevanceScore = entry.relevanceScore;
    final targetAgeBands = entry.targetAgeBands
        .map((ageBand) => ageBand.trim())
        .toList(growable: false);

    if (!DailyKeywordTypes.allowed.contains(type) ||
        keyword.isEmpty ||
        hint.isEmpty ||
        plantHint == null ||
        plantHint.isEmpty ||
        tone == null ||
        !DailyKeywordTones.allowed.contains(tone) ||
        fitScore == null ||
        !fitScore.isFinite ||
        fitScore < minimumFitScore ||
        fitScore > 1 ||
        (relevanceScore != null &&
            (!relevanceScore.isFinite ||
                relevanceScore < 0 ||
                relevanceScore > 1)) ||
        targetAgeBands.any(
          (ageBand) => !DailyKeywordAgeBands.allowed.contains(ageBand),
        ) ||
        [
          keyword,
          hint,
          plantHint,
          entry.category ?? '',
        ].any(BlockedKeywordCatalog.containsBlockedTerm)) {
      return null;
    }

    return DailyConversationMaterial(
      type: type,
      keyword: keyword,
      hint: hint,
      plantHint: plantHint,
      tone: tone,
      fitScore: fitScore,
      category: entry.category?.trim(),
      relevanceScore: relevanceScore,
      targetAgeBands: targetAgeBands,
    );
  }

  bool _isSameCalendarDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
