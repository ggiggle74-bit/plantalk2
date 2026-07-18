import '../models/daily_keyword_context.dart';
import 'catalogs/blocked_keyword_catalog.dart';
import 'models/daily_keyword_candidate.dart';
import 'models/daily_opening_context.dart';

class DailyOpeningKeywordSelector {
  const DailyOpeningKeywordSelector({this.minimumFitScore = 0.60});

  final double minimumFitScore;

  DailyOpeningContext? project({
    required DailyKeywordContext? context,
    required DateTime now,
    required bool isOpeningTurn,
    required int seed,
  }) {
    final selectedCandidate = select(
      context: context,
      now: now,
      isOpeningTurn: isOpeningTurn,
      seed: seed,
    );
    if (selectedCandidate == null) {
      return null;
    }

    return DailyOpeningContext(selectedCandidate: selectedCandidate);
  }

  DailyKeywordEntry? select({
    required DailyKeywordContext? context,
    required DateTime now,
    required bool isOpeningTurn,
    required int seed,
  }) {
    if (!isOpeningTurn || context == null || !context.hasKeywords) {
      return null;
    }
    if (!_isSameCalendarDate(context.date, now)) {
      return null;
    }

    final eligibleEntries = context.keywords
        .where(_isEligible)
        .toList(growable: false);
    if (eligibleEntries.isEmpty) {
      return null;
    }

    final index = seed.remainder(eligibleEntries.length).abs();
    return eligibleEntries[index];
  }

  bool _isEligible(DailyKeywordEntry entry) {
    final type = entry.type.trim().toLowerCase();
    final keyword = entry.keyword.trim();
    final hint = entry.hint.trim();
    final plantHint = entry.plantHint?.trim();
    final tone = entry.tone?.trim().toLowerCase();
    final fitScore = entry.fitScore;

    if (!DailyKeywordTypes.allowed.contains(type) ||
        keyword.isEmpty ||
        hint.isEmpty ||
        (plantHint != null && plantHint.isEmpty) ||
        (tone != null && !DailyKeywordTones.allowed.contains(tone))) {
      return false;
    }
    if (fitScore != null &&
        (!fitScore.isFinite ||
            fitScore < minimumFitScore ||
            fitScore > 1.0)) {
      return false;
    }

    return ![
      keyword,
      hint,
      plantHint ?? '',
      entry.category ?? '',
    ].any(BlockedKeywordCatalog.containsBlockedTerm);
  }

  bool _isSameCalendarDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
