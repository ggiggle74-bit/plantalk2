import '../models/normalized_plant_event.dart';

class PlantConditionRepresentativeEventSelector {
  const PlantConditionRepresentativeEventSelector();

  NormalizedPlantEvent select(List<NormalizedPlantEvent> events) {
    if (events.isEmpty) {
      throw StateError(
        'Cannot select a representative condition event from an empty list.',
      );
    }

    var selected = events.first;

    for (final event in events.skip(1)) {
      if (_outranks(event, selected)) {
        selected = event;
      }
    }

    return selected;
  }

  bool _outranks(NormalizedPlantEvent candidate, NormalizedPlantEvent current) {
    final candidateGroup = _groupRank(candidate.eventType);
    final currentGroup = _groupRank(current.eventType);
    if (candidateGroup != currentGroup) {
      return candidateGroup > currentGroup;
    }

    final candidateConfidence = candidate.confidence;
    final currentConfidence = current.confidence;
    if (candidateConfidence != null && currentConfidence == null) {
      return true;
    }
    if (candidateConfidence == null && currentConfidence != null) {
      return false;
    }
    if (candidateConfidence != null && currentConfidence != null) {
      if (candidateConfidence != currentConfidence) {
        return candidateConfidence > currentConfidence;
      }
    }

    if (candidateGroup == _eventGroupActionable) {
      final candidatePriority = _actionablePriority(candidate.eventType);
      final currentPriority = _actionablePriority(current.eventType);
      if (candidatePriority != currentPriority) {
        return candidatePriority > currentPriority;
      }
    }

    return false;
  }

  int _groupRank(String eventType) {
    switch (PlantAnalysisEventTypes.normalize(eventType)) {
      case PlantAnalysisEventTypes.waterNeeded:
      case PlantAnalysisEventTypes.overwaterSuspected:
      case PlantAnalysisEventTypes.lightNeeded:
      case PlantAnalysisEventTypes.tooMuchSunSuspected:
      case PlantAnalysisEventTypes.pestSuspected:
      case PlantAnalysisEventTypes.diseaseSuspected:
      case PlantAnalysisEventTypes.repottingSuggested:
      case PlantAnalysisEventTypes.soilCheckNeeded:
      case PlantAnalysisEventTypes.temperatureStressSuspected:
      case PlantAnalysisEventTypes.humidityIssueSuspected:
        return _eventGroupActionable;
      case PlantAnalysisEventTypes.conditionUncertain:
        return _eventGroupUncertain;
      case PlantAnalysisEventTypes.healthOk:
      case PlantAnalysisEventTypes.growthPositive:
      case PlantAnalysisEventTypes.newLeafObserved:
      case PlantAnalysisEventTypes.floweringObserved:
      default:
        return _eventGroupPositive;
    }
  }

  int _actionablePriority(String eventType) {
    switch (PlantAnalysisEventTypes.normalize(eventType)) {
      case PlantAnalysisEventTypes.pestSuspected:
      case PlantAnalysisEventTypes.diseaseSuspected:
        return 4;
      case PlantAnalysisEventTypes.overwaterSuspected:
      case PlantAnalysisEventTypes.tooMuchSunSuspected:
      case PlantAnalysisEventTypes.repottingSuggested:
      case PlantAnalysisEventTypes.soilCheckNeeded:
      case PlantAnalysisEventTypes.temperatureStressSuspected:
      case PlantAnalysisEventTypes.humidityIssueSuspected:
        return 3;
      case PlantAnalysisEventTypes.waterNeeded:
        return 2;
      case PlantAnalysisEventTypes.lightNeeded:
        return 1;
      default:
        return 0;
    }
  }
}

const _eventGroupPositive = 1;
const _eventGroupUncertain = 2;
const _eventGroupActionable = 3;
