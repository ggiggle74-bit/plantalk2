import '../adapters/kindwise_plant_health_adapter.dart';
import '../adapters/kindwise_plant_health_response_parser.dart';
import '../adapters/supabase_kindwise_plant_health_proxy.dart';
import '../normalizers/plant_analysis_normalizer.dart';
import '../services/plant_analysis_service.dart';

class KindwisePlantHealthServiceFactory {
  const KindwisePlantHealthServiceFactory.withProxyCallback({
    required InvokeKindwisePlantHealthProxyCallback invokeProxy,
    KindwisePlantHealthResponseParser parser =
        const KindwisePlantHealthResponseParser(),
    PlantAnalysisNormalizer normalizer = const PlantAnalysisNormalizer(),
  }) : _invokeProxy = invokeProxy,
       _parser = parser,
       _normalizer = normalizer;

  factory KindwisePlantHealthServiceFactory.withSupabaseFunctionInvoker({
    required InvokeSupabaseKindwisePlantHealthFunctionCallback invokeFunction,
    KindwisePlantHealthResponseParser parser =
        const KindwisePlantHealthResponseParser(),
    PlantAnalysisNormalizer normalizer = const PlantAnalysisNormalizer(),
  }) {
    return KindwisePlantHealthServiceFactory.supabase(
      proxy: SupabaseKindwisePlantHealthProxy(invokeFunction: invokeFunction),
      parser: parser,
      normalizer: normalizer,
    );
  }

  factory KindwisePlantHealthServiceFactory.supabase({
    SupabaseKindwisePlantHealthProxy proxy =
        const SupabaseKindwisePlantHealthProxy(),
    KindwisePlantHealthResponseParser parser =
        const KindwisePlantHealthResponseParser(),
    PlantAnalysisNormalizer normalizer = const PlantAnalysisNormalizer(),
  }) {
    return KindwisePlantHealthServiceFactory.withProxyCallback(
      invokeProxy: proxy.invoke,
      parser: parser,
      normalizer: normalizer,
    );
  }

  final InvokeKindwisePlantHealthProxyCallback _invokeProxy;
  final KindwisePlantHealthResponseParser _parser;
  final PlantAnalysisNormalizer _normalizer;

  PlantAnalysisService build() {
    return PlantAnalysisService(
      adapter: KindwisePlantHealthAdapter(
        invokeProxy: _invokeProxy,
        parser: _parser,
      ),
      normalizer: _normalizer,
    );
  }
}
