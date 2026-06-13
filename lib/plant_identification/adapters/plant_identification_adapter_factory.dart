import 'mock_plant_identification_adapter.dart';
import 'plant_identification_adapter.dart';
import 'plantnet_plant_identification_adapter.dart';

class PlantIdentificationAdapterFactory {
  const PlantIdentificationAdapterFactory._();

  static const bool _usePlantNet = bool.fromEnvironment(
    'PLANTNET_ENABLED',
    defaultValue: false,
  );
  static const String _plantNetApiKey = String.fromEnvironment(
    'PLANTNET_API_KEY',
  );
  static const String _plantNetProject = String.fromEnvironment(
    'PLANTNET_PROJECT',
    defaultValue: 'all',
  );

  static PlantIdentificationAdapter firstRegistrationAdapter() {
    if (!usePlantNetForDev) {
      return const MockPlantIdentificationAdapter();
    }

    return const PlantNetPlantIdentificationAdapter(
      apiKey: _plantNetApiKey,
      project: _plantNetProject,
    );
  }

  static PlantIdentificationAdapter mockAdapter() {
    return const MockPlantIdentificationAdapter();
  }

  static bool get usePlantNetForDev {
    return _usePlantNet && _plantNetApiKey.trim().isNotEmpty;
  }
}
