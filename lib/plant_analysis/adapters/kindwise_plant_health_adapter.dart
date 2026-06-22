import '../models/external_plant_analysis_result.dart';
import '../models/plant_analysis_input.dart';
import 'kindwise_plant_health_response_parser.dart';
import 'plant_analysis_adapter.dart';

typedef InvokeKindwisePlantHealthProxyCallback =
    Future<Object?> Function({required String imageUrl});

class KindwisePlantHealthAdapter implements PlantAnalysisAdapter {
  const KindwisePlantHealthAdapter({
    required InvokeKindwisePlantHealthProxyCallback invokeProxy,
    KindwisePlantHealthResponseParser parser =
        const KindwisePlantHealthResponseParser(),
  }) : _invokeProxy = invokeProxy,
       _parser = parser;

  final InvokeKindwisePlantHealthProxyCallback _invokeProxy;
  final KindwisePlantHealthResponseParser _parser;

  @override
  String get providerKey => KindwisePlantHealthResponseParser.providerKey;

  @override
  Future<ExternalPlantAnalysisResult> analyze(PlantAnalysisInput input) async {
    _validateAnalysisType(input.analysisType);
    final imageUrl = _validatedImageUrl(input.imageUrl);
    final response = await _invokeProxy(imageUrl: imageUrl);

    return _resultFromProxyResponse(response, input);
  }

  void _validateAnalysisType(String analysisType) {
    if (analysisType == PlantAnalysisTypes.conditionCheck) {
      return;
    }

    throw UnsupportedError(
      'Kindwise plant.health adapter supports condition_check only.',
    );
  }

  String _validatedImageUrl(String? value) {
    final imageUrl = value?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw StateError('Kindwise plant.health proxy requires an imageUrl.');
    }

    final uri = Uri.tryParse(imageUrl);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        !uri.hasScheme ||
        (scheme != 'http' && scheme != 'https') ||
        uri.host.trim().isEmpty) {
      throw StateError(
        'Kindwise plant.health proxy requires an absolute HTTP or HTTPS imageUrl.',
      );
    }

    return imageUrl;
  }

  ExternalPlantAnalysisResult _resultFromProxyResponse(
    Object? response,
    PlantAnalysisInput input,
  ) {
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
      'Unexpected Kindwise plant-health proxy response shape.',
    );
  }
}
