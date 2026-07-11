class DailyKeywordSourceRequest {
  DailyKeywordSourceRequest({
    required this.date,
    required this.locale,
    Iterable<String> weatherSignals = const [],
  }) : weatherSignals = List.unmodifiable(weatherSignals);

  final DateTime date;
  final String locale;
  final List<String> weatherSignals;
}
