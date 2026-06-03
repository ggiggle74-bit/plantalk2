import '../models/external_plant_analysis_result.dart';
import '../models/plant_analysis_input.dart';

abstract class PlantAnalysisAdapter {
  String get providerKey;

  Future<ExternalPlantAnalysisResult> analyze(PlantAnalysisInput input);
}
