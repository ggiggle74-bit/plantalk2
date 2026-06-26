import '../adapters/gemini_default_state_observation_adapter.dart';
import '../adapters/gemini_default_state_observation_parser.dart';
import '../adapters/supabase_gemini_default_observation_proxy.dart';
import '../normalizers/plant_analysis_normalizer.dart';
import '../services/plant_analysis_service.dart';

class GeminiDefaultObservationServiceFactory {
  const GeminiDefaultObservationServiceFactory.withProxyCallback({
    required InvokeGeminiDefaultObservationProxyCallback invokeProxy,
    GeminiDefaultStateObservationParser parser =
        const GeminiDefaultStateObservationParser(),
    PlantAnalysisNormalizer normalizer = const PlantAnalysisNormalizer(),
  }) : _invokeProxy = invokeProxy,
       _parser = parser,
       _normalizer = normalizer;

  factory GeminiDefaultObservationServiceFactory.supabase({
    SupabaseGeminiDefaultObservationProxy proxy =
        const SupabaseGeminiDefaultObservationProxy(),
    GeminiDefaultStateObservationParser parser =
        const GeminiDefaultStateObservationParser(),
    PlantAnalysisNormalizer normalizer = const PlantAnalysisNormalizer(),
  }) {
    return GeminiDefaultObservationServiceFactory.withProxyCallback(
      invokeProxy: proxy.invoke,
      parser: parser,
      normalizer: normalizer,
    );
  }

  final InvokeGeminiDefaultObservationProxyCallback _invokeProxy;
  final GeminiDefaultStateObservationParser _parser;
  final PlantAnalysisNormalizer _normalizer;

  PlantAnalysisService build() {
    return PlantAnalysisService(
      adapter: GeminiDefaultStateObservationAdapter(
        invokeProxy: _invokeProxy,
        parser: _parser,
      ),
      normalizer: _normalizer,
    );
  }
}
