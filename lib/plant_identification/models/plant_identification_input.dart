class PlantIdentificationInput {
  const PlantIdentificationInput({
    required this.imageUrl,
    required this.locale,
    required this.requestedAt,
    required this.source,
    this.plantId,
    this.userId,
  });

  final String imageUrl;
  final String? plantId;
  final String? userId;
  final String locale;
  final DateTime requestedAt;
  final String source;
}
