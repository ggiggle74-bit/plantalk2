import 'dart:typed_data';

/// Photo identification request data for first-time plant registration.
///
/// This boundary runs before a Plant exists, so it must not carry or require a
/// Plant id.
class PlantIdentificationInput {
  const PlantIdentificationInput({
    required this.imageUrl,
    required this.locale,
    required this.requestedAt,
    required this.source,
    this.userId,
    this.imageBytes,
    this.fileName,
    this.mimeType,
  });

  final String imageUrl;
  final Uint8List? imageBytes;
  final String? fileName;
  final String? mimeType;
  final String? userId;
  final String locale;
  final DateTime requestedAt;
  final String source;
}
