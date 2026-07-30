import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deep flow checks authorization before provider work', () {
    final source = File(
      'lib/services/deep_health_assessment_flow_service.dart',
    ).readAsStringSync();

    final gateIndex = source.indexOf('_gateService.authorizeAndReserve');
    final photoIndex = source.indexOf('_savePhoto(');
    final analysisIndex = source.indexOf('_analyze(');
    final memoryIndex = source.indexOf('_insertMemory(');
    final commitIndex = source.indexOf('_gateService.commitReservation');

    expect(gateIndex, greaterThanOrEqualTo(0));
    expect(photoIndex, greaterThan(gateIndex));
    expect(analysisIndex, greaterThan(photoIndex));
    expect(memoryIndex, greaterThan(analysisIndex));
    expect(commitIndex, greaterThan(memoryIndex));
  });

  test('failed deep work has an explicit reservation release path', () {
    final source = File(
      'lib/services/deep_health_assessment_flow_service.dart',
    ).readAsStringSync();

    expect(source, contains('_gateService.releaseReservation'));
    expect(source, contains('Error.throwWithStackTrace'));
    expect(
      source,
      contains('DeepHealthAssessmentUsageRecoveryException'),
    );
  });

  test('paid deep flow rejects mock analysis', () {
    final source = File(
      'lib/services/deep_health_assessment_flow_service.dart',
    ).readAsStringSync();

    expect(source, contains('result.isMock'));
    expect(source, contains('result.normalizedEvent.isMock'));
    expect(
      source,
      contains('Paid deep health assessment must not complete with mock data.'),
    );
  });

  test('deep memory type stays separate from ordinary condition memory', () {
    final source = File(
      'lib/plant_analysis/bridges/'
      'deep_health_assessment_memory_payload_bridge.dart',
    ).readAsStringSync();

    expect(source, contains("'deep_health_assessment'"));
    expect(source, contains('deepHealthAssessmentMemoryType'));
  });

  test('deep flow remains outside runtime composition', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource, isNot(contains('DeepHealthAssessmentFlowService')));
    expect(mainSource, isNot(contains('deep_health_assessment_flow_service')));
  });

  test('slot contract has no provider, UI, or local gate dependency', () {
    final source = File(
      'lib/services/deep_health_assessment_flow_service.dart',
    ).readAsStringSync();
    final normalized = source.toLowerCase();

    const forbidden = [
      'supabase',
      'kindwise',
      'gemini',
      'localentitlementgateservice',
      'local_entitlement_gate_service',
      'main.dart',
      'chat_panel',
      'flutter/material.dart',
    ];

    for (final snippet in forbidden) {
      expect(
        normalized,
        isNot(contains(snippet)),
        reason: 'deep slot contract must not reference $snippet',
      );
    }
  });
}
