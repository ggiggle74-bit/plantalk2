import '../models/external_plant_analysis_result.dart';
import '../models/plant_analysis_input.dart';
import 'kindwise_plant_health_response_parser.dart';
import 'plant_analysis_adapter.dart';

typedef InvokeReservedKindwisePlantHealthProxyCallback =
    Future<Object?> Function({
      required String imageUrl,
      required String reservationId,
    });

class ReservedKindwisePlantHealthAdapter implements PlantAnalysisAdapter {
  const ReservedKindwisePlantHealthAdapter({
    required InvokeReservedKindwisePlantHealthProxyCallback invokeProxy,
    KindwisePlantHealthResponseParser parser =
        const KindwisePlantHealthResponseParser(),
  }) : _invokeProxy = invokeProxy,
       _parser = parser;

  final InvokeReservedKindwisePlantHealthProxyCallback _invokeProxy;
  final KindwisePlantHealthResponseParser _parser;

  @override
  String get providerKey => KindwisePlantHealthResponseParser.providerKey;

  @override
  Future<ExternalPlantAnalysisResult> analyze(PlantAnalysisInput input) async {
    if (input.analysisType != PlantAnalysisTypes.conditionCheck) {
      throw UnsupportedError(
        'Reserved Kindwise plant.health adapter supports condition_check only.',
      );
    }

    final imageUrl = _validatedImageUrl(input.imageUrl);
    final reservationId = _validatedReservationId(
      input.deepHealthReservationId,
    );
    final response = await _invokeProxy(
      imageUrl: imageUrl,
      reservationId: reservationId,
    );

    if (response is Map<String, dynamic>) {
      return _parser.resultFromMap(response, input);
    }
    if (response is Map) {
      return _parser.resultFromMap(Map<String, dynamic>.from(response), input);
    }
    if (response is String) {
      return _parser.resultFromJson(response, input);
    }

    throw const FormatException(
      'Unexpected reserved Kindwise plant-health proxy response shape.',
    );
  }

  String _validatedImageUrl(String? value) {
    final imageUrl = value?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw StateError('Reserved Kindwise proxy requires an imageUrl.');
    }

    final uri = Uri.tryParse(imageUrl);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        !uri.hasScheme ||
        (scheme != 'http' && scheme != 'https') ||
        uri.host.trim().isEmpty) {
      throw StateError(
        'Reserved Kindwise proxy requires an absolute HTTP or HTTPS imageUrl.',
      );
    }

    return imageUrl;
  }

  String _validatedReservationId(String? value) {
    final reservationId = value?.trim();
    if (reservationId == null || reservationId.isEmpty) {
      throw StateError(
        'Reserved Kindwise proxy requires a deep health usage reservation.',
      );
    }
    return reservationId;
  }
}
