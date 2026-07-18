import '../../models/daily_keyword_context.dart';

class DailyOpeningContext {
  DailyOpeningContext({required this.selectedCandidate});

  final DailyKeywordEntry selectedCandidate;
  final bool firstGreetingOnly = true;

  DateTime? _consumedAt;

  DateTime? get consumedAt => _consumedAt;
  bool get isConsumed => _consumedAt != null;

  DailyKeywordEntry? consume({
    required bool isOpeningTurn,
    required DateTime consumedAt,
  }) {
    if (!isOpeningTurn || isConsumed) {
      return null;
    }

    _consumedAt = consumedAt;
    return selectedCandidate;
  }
}
