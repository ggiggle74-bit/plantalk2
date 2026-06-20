import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/selectors/plant_condition_representative_event_selector.dart';

void main() {
  const selector = PlantConditionRepresentativeEventSelector();

  test('actionable outranks normal regardless of confidence', () {
    final health = _event(PlantAnalysisEventTypes.healthOk, confidence: 0.99);
    final water = _event(PlantAnalysisEventTypes.waterNeeded);

    expect(selector.select([health, water]), same(water));
  });

  test('actionable outranks uncertain', () {
    final uncertain = _event(
      PlantAnalysisEventTypes.conditionUncertain,
      confidence: 0.99,
    );
    final light = _event(PlantAnalysisEventTypes.lightNeeded, confidence: 0.40);

    expect(selector.select([uncertain, light]), same(light));
  });

  test('confidence wins inside actionable events', () {
    final pest = _event(
      PlantAnalysisEventTypes.pestSuspected,
      confidence: 0.70,
    );
    final light = _event(PlantAnalysisEventTypes.lightNeeded, confidence: 0.90);

    expect(selector.select([pest, light]), same(light));
  });

  test('attention priority breaks equal-confidence ties', () {
    final water = _event(PlantAnalysisEventTypes.waterNeeded, confidence: 0.80);
    final disease = _event(
      PlantAnalysisEventTypes.diseaseSuspected,
      confidence: 0.80,
    );

    expect(selector.select([water, disease]), same(disease));
  });

  test('provider order breaks an exact tie', () {
    final pest = _event(
      PlantAnalysisEventTypes.pestSuspected,
      confidence: 0.80,
    );
    final disease = _event(
      PlantAnalysisEventTypes.diseaseSuspected,
      confidence: 0.80,
    );

    expect(selector.select([pest, disease]), same(pest));
  });

  test('uncertainty outranks positive or normal without actionable events', () {
    final health = _event(PlantAnalysisEventTypes.healthOk, confidence: 0.95);
    final uncertain = _event(
      PlantAnalysisEventTypes.conditionUncertain,
      confidence: 0.20,
    );

    expect(selector.select([health, uncertain]), same(uncertain));
  });

  test('highest confidence wins among positive and normal events', () {
    final growth = _event(
      PlantAnalysisEventTypes.growthPositive,
      confidence: 0.60,
    );
    final health = _event(PlantAnalysisEventTypes.healthOk, confidence: 0.90);

    expect(selector.select([growth, health]), same(health));
  });

  test('numeric confidence outranks null confidence', () {
    final water = _event(PlantAnalysisEventTypes.waterNeeded);
    final light = _event(PlantAnalysisEventTypes.lightNeeded, confidence: 0.10);

    expect(selector.select([water, light]), same(light));
  });

  test('does not mutate input and returns original event object', () {
    final health = _event(PlantAnalysisEventTypes.healthOk, confidence: 0.99);
    final pest = _event(
      PlantAnalysisEventTypes.pestSuspected,
      confidence: 0.40,
    );
    final events = [health, pest];

    final selected = selector.select(events);

    expect(selected, same(pest));
    expect(events[0], same(health));
    expect(events[1], same(pest));
  });

  test('throws clear StateError for empty input', () {
    expect(
      () => selector.select(const []),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('empty list'),
        ),
      ),
    );
  });
}

NormalizedPlantEvent _event(String eventType, {double? confidence}) {
  return NormalizedPlantEvent(
    eventType: eventType,
    sourceProvider: 'test_provider',
    confidence: confidence,
    message: 'message for $eventType',
    observedAt: DateTime.utc(2026, 6, 20),
    sourceResultId: 'result-$eventType',
    isMock: true,
    metadata: {'eventType': eventType},
  );
}
