import '../models/plant_identification_input.dart';
import '../models/plant_identification_result.dart';

abstract class PlantIdentificationAdapter {
  String get providerKey;

  Future<PlantIdentificationResult> identify(PlantIdentificationInput input);
}
