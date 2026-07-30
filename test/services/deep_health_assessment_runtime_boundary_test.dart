import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deep UI is exposed only for persisted plant cards', () {
    final cardSource = File('lib/widgets/plant_card.dart').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(cardSource, contains('onDeepHealthAssessment'));
    expect(cardSource, contains('심층 진단'));
    expect(
      mainSource,
      contains('handleDeepHealthAssessment(context, plant)'),
    );
    expect(
      mainSource,
      contains('isDeepHealthAssessmentInProgress'),
    );
  });

  test('deep runtime uses a server gate and a reserved provider service', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mainSource,
      contains('SupabaseDeepHealthAssessmentGateService'),
    );
    expect(
      mainSource,
      contains('SupabaseDeepHealthAssessmentAnalysisService'),
    );
    expect(
      mainSource,
      isNot(contains('LocalEntitlementGateService')),
    );
  });

  test('reserved provider refuses to invoke without a reservation id', () {
    final source = File(
      'lib/plant_analysis/adapters/reserved_kindwise_plant_health_adapter.dart',
    ).readAsStringSync();

    expect(source, contains('deepHealthReservationId'));
    expect(source, contains('requires a deep health usage reservation'));
    expect(source, contains('required String reservationId'));
  });

  test('Edge Function claims usage before the Kindwise request', () {
    final source = File(
      'supabase/functions/plant-health-assess/handler.ts',
    ).readAsStringSync();

    final claimIndex = source.indexOf('claimReservation({ authorization, reservationId })');
    final kindwiseIndex = source.indexOf('const kindwiseUrl = new URL(kindwiseEndpoint)');

    expect(source, contains('claim_deep_health_assessment_usage'));
    expect(source, contains('readBearerAuthorization'));
    expect(source, contains('reservationId is required.'));
    expect(claimIndex, greaterThanOrEqualTo(0));
    expect(kindwiseIndex, greaterThan(claimIndex));
  });

  test('claimed reservations are counted and may be released or committed', () {
    final migration = File(
      'supabase/migrations/20260730080000_claim_deep_health_usage.sql',
    ).readAsStringSync();

    expect(migration, contains("'claimed'"));
    expect(migration, contains('claim_deep_health_assessment_usage'));
    expect(migration, contains("status in ('reserved', 'claimed')"));
    expect(migration, contains("set status = 'committed'"));
    expect(migration, contains("set status = 'released'"));
    expect(migration, contains('to authenticated'));
  });
}
