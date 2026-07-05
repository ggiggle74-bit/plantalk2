import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/monetization/models/entitlement_check_context.dart';
import 'package:plantalk2/monetization/models/paid_feature.dart';
import 'package:plantalk2/monetization/services/local_entitlement_gate_service.dart';

void main() {
  test(
    'allows deep health assessment when freeRemaining is positive',
    () async {
      const service = LocalEntitlementGateService(
        deepHealthAssessmentFreeRemaining: 1,
      );

      final result = await service.check(PaidFeature.deepHealthAssessment);

      expect(result.allowed, isTrue);
      expect(result.requiresPayment, isFalse);
      expect(result.freeRemaining, 1);
      expect(result.message, '무료 심층 분석이 1회 남아 있어요.');
    },
  );

  test(
    'requires payment for deep health assessment when freeRemaining is zero',
    () async {
      const service = LocalEntitlementGateService(
        deepHealthAssessmentFreeRemaining: 0,
      );

      final result = await service.check(PaidFeature.deepHealthAssessment);

      expect(result.allowed, isFalse);
      expect(result.requiresPayment, isTrue);
      expect(result.freeRemaining, 0);
      expect(result.message, '무료 심층 분석을 모두 사용했어요.');
    },
  );

  test(
    'requires payment for deep health assessment when freeRemaining is negative',
    () async {
      const service = LocalEntitlementGateService(
        deepHealthAssessmentFreeRemaining: -1,
      );

      final result = await service.check(PaidFeature.deepHealthAssessment);

      expect(result.allowed, isFalse);
      expect(result.requiresPayment, isTrue);
      expect(result.freeRemaining, -1);
    },
  );

  test(
    'allows plant character creation when currentPlantCount is below limit',
    () async {
      const service = LocalEntitlementGateService(plantCharacterLimit: 3);

      final result = await service.check(
        PaidFeature.plantCharacterSlot,
        context: const EntitlementCheckContext(currentPlantCount: 2),
      );

      expect(result.allowed, isTrue);
      expect(result.requiresPayment, isFalse);
      expect(result.currentUsage, 2);
      expect(result.limit, 3);
      expect(result.message, '새 식물 캐릭터를 만들 수 있어요.');
    },
  );

  test('uses currentUsage as plant slot fallback count', () async {
    const service = LocalEntitlementGateService(plantCharacterLimit: 3);

    final result = await service.check(
      PaidFeature.plantCharacterSlot,
      context: const EntitlementCheckContext(currentUsage: 1),
    );

    expect(result.allowed, isTrue);
    expect(result.currentUsage, 1);
    expect(result.limit, 3);
  });

  test('requires payment when plant character count reaches limit', () async {
    const service = LocalEntitlementGateService(plantCharacterLimit: 3);

    final result = await service.check(
      PaidFeature.plantCharacterSlot,
      context: const EntitlementCheckContext(currentPlantCount: 3),
    );

    expect(result.allowed, isFalse);
    expect(result.requiresPayment, isTrue);
    expect(result.currentUsage, 3);
    expect(result.limit, 3);
    expect(result.message, '식물 캐릭터 한도에 도달했어요.');
  });

  test('requires payment when plant character count exceeds limit', () async {
    const service = LocalEntitlementGateService(plantCharacterLimit: 3);

    final result = await service.check(
      PaidFeature.plantCharacterSlot,
      context: const EntitlementCheckContext(currentPlantCount: 4),
    );

    expect(result.allowed, isFalse);
    expect(result.requiresPayment, isTrue);
    expect(result.currentUsage, 4);
    expect(result.limit, 3);
  });

  test('does not import provider, Supabase, analysis, or UI dependencies', () {
    final source = File(
      'lib/monetization/services/local_entitlement_gate_service.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('supabase')));
    expect(source, isNot(contains('plant_analysis')));
    expect(source, isNot(contains('Gemini')));
    expect(source, isNot(contains('Kindwise')));
    expect(source, isNot(contains('flutter/material.dart')));
    expect(source, isNot(contains('widgets')));
  });
}
