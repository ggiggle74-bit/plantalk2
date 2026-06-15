import 'mock_plant_identification_adapter.dart';
import 'plant_identification_adapter.dart';
import 'plantnet_plant_identification_adapter.dart';
import 'supabase_plant_identification_adapter.dart';

class PlantIdentificationAdapterFactory {
  const PlantIdentificationAdapterFactory._();

  static const bool _isProductBuild = bool.fromEnvironment('dart.vm.product');
  static const bool _useDirectPlantNetDevOnly = bool.fromEnvironment(
    'PLANTNET_DIRECT_DEV_ONLY',
    defaultValue: false,
  );
  static const String _directPlantNetDevOnlyApiKey = String.fromEnvironment(
    'PLANTNET_DIRECT_DEV_ONLY_API_KEY',
  );
  static const String _plantNetProject = String.fromEnvironment(
    'PLANTNET_PROJECT',
    defaultValue: 'all',
  );

  static PlantIdentificationAdapter firstRegistrationAdapter() {
    if (useDirectPlantNetForDevOnly) {
      return const PlantNetPlantIdentificationAdapter(
        apiKey: _directPlantNetDevOnlyApiKey,
        project: _plantNetProject,
      );
    }

    return const SupabasePlantIdentificationAdapter(project: _plantNetProject);
  }

  static PlantIdentificationAdapter mockAdapter() {
    return const MockPlantIdentificationAdapter();
  }

  static bool get useDirectPlantNetForDevOnly {
    return !_isProductBuild &&
        _useDirectPlantNetDevOnly &&
        _directPlantNetDevOnlyApiKey.trim().isNotEmpty;
  }
}
