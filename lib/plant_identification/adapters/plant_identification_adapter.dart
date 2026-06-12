import '../models/plant_identification_input.dart';
import '../models/plant_identification_result.dart';

/// Replaceable boundary for providers that return candidate plant identities.
abstract class PlantIdentificationAdapter {
  String get providerKey;

  Future<PlantIdentificationResult> identify(PlantIdentificationInput input);
}
