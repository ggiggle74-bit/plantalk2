class DailyKeywordSourceRequest {
  DailyKeywordSourceRequest({
    required this.date,
    required this.locale,
    this.regionCode = 'global',
    Iterable<String> weatherSignals = const [],
  }) : weatherSignals = List.unmodifiable(weatherSignals);

  final DateTime date;
  final String locale;
  final String regionCode;
  final List<String> weatherSignals;
}
