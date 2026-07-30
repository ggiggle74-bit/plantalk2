import '../plant_analysis/adapters/kindwise_plant_health_response_parser.dart';
import '../plant_analysis/adapters/reserved_kindwise_plant_health_adapter.dart';
import '../plant_analysis/adapters/supabase_kindwise_plant_health_proxy.dart';
import '../plant_analysis/normalizers/plant_analysis_normalizer.dart';
import '../plant_analysis/services/plant_analysis_service.dart';
import 'plant_condition_analysis_service.dart';

class SupabaseDeepHealthAssessmentAnalysisService
    implements PlantConditionAnalysisService {
  const SupabaseDeepHealthAssessmentAnalysisService._({
    required PlantConditionAnalysisService delegate,
  }) : _delegate = delegate;

  factory SupabaseDeepHealthAssessmentAnalysisService({
    SupabaseKindwisePlantHealthProxy proxy =
        const SupabaseKindwisePlantHealthProxy(),
    KindwisePlantHealthResponseParser parser =
        const KindwisePlantHealthResponseParser(),
    PlantAnalysisNormalizer normalizer = const PlantAnalysisNormalizer(),
  }) {
    final service = PlantAnalysisService(
      adapter: ReservedKindwisePlantHealthAdapter(
        invokeProxy: ({required imageUrl, required reservationId}) {
          return proxy.invoke(
            imageUrl: imageUrl,
            reservationId: reservationId,
          );
        },
        parser: parser,
      ),
      normalizer: normalizer,
    );

    return SupabaseDeepHealthAssessmentAnalysisService._(
      delegate: PlantAnalysisBackedConditionAnalysisService(
        plantAnalysisService: service,
        analysisType: 'condition_check',
      ),
    );
  }

  final PlantConditionAnalysisService _delegate;

  @override
  Future<PlantConditionAnalysisResult> analyzeCondition(
    PlantConditionAnalysisRequest request,
  ) {
    return _delegate.analyzeCondition(request);
  }
}
