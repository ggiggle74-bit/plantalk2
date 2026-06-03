class NormalizedPlantEvent {
  const NormalizedPlantEvent({
    required this.eventType,
    required this.sourceProvider,
    this.confidence,
    this.message,
    this.observedAt,
    this.sourceResultId,
    this.isMock = false,
    this.metadata = const {},
  });

  final String eventType;
  final String sourceProvider;
  final double? confidence;
  final String? message;
  final DateTime? observedAt;
  final String? sourceResultId;
  final bool isMock;
  final Map<String, Object?> metadata;
}

class PlantAnalysisEventTypes {
  const PlantAnalysisEventTypes._();

  static const healthOk = 'health_ok';
  static const waterNeeded = 'water_needed';
  static const overwaterSuspected = 'overwater_suspected';
  static const lightNeeded = 'light_needed';
  static const tooMuchSunSuspected = 'too_much_sun_suspected';
  static const pestSuspected = 'pest_suspected';
  static const diseaseSuspected = 'disease_suspected';
  static const growthPositive = 'growth_positive';
  static const newLeafObserved = 'new_leaf_observed';
  static const floweringObserved = 'flowering_observed';
  static const repottingSuggested = 'repotting_suggested';
  static const soilCheckNeeded = 'soil_check_needed';
  static const temperatureStressSuspected = 'temperature_stress_suspected';
  static const humidityIssueSuspected = 'humidity_issue_suspected';
  static const conditionUncertain = 'condition_uncertain';

  static const all = <String>{
    healthOk,
    waterNeeded,
    overwaterSuspected,
    lightNeeded,
    tooMuchSunSuspected,
    pestSuspected,
    diseaseSuspected,
    growthPositive,
    newLeafObserved,
    floweringObserved,
    repottingSuggested,
    soilCheckNeeded,
    temperatureStressSuspected,
    humidityIssueSuspected,
    conditionUncertain,
  };

  static String normalize(String? eventType) {
    final normalized = eventType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return conditionUncertain;
    }

    return all.contains(normalized) ? normalized : conditionUncertain;
  }
}
