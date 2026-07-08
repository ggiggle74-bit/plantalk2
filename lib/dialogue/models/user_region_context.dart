class UserRegionContext {
  const UserRegionContext({
    required this.countryCode,
    required this.regionLabel,
    this.localityLabel,
    required this.precision,
    required this.source,
  });

  final String countryCode;
  final String regionLabel;
  final String? localityLabel;
  final String precision;
  final String source;
}
