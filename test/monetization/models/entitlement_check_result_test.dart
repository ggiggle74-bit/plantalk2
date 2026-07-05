import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/monetization/models/entitlement_check_result.dart';
import 'package:plantalk2/monetization/models/paid_feature.dart';

void main() {
  test('allowed state can drive UI copy', () {
    final result = EntitlementCheckResult.allowed(
      feature: PaidFeature.plantCharacterSlot,
      currentUsage: 1,
      limit: 3,
    );

    expect(result.feature, PaidFeature.plantCharacterSlot);
    expect(result.allowed, isTrue);
    expect(result.requiresPayment, isFalse);
    expect(result.currentUsage, 1);
    expect(result.limit, 3);
    expect(result.message, '새 식물 캐릭터를 만들 수 있어요.');
    expect(result.primaryCta, '계속하기');
    expect(result.secondaryCta, '취소');
  });

  test('usage remaining state includes free remaining count', () {
    final result = EntitlementCheckResult.usageRemaining(
      feature: PaidFeature.deepHealthAssessment,
      freeRemaining: 2,
      currentUsage: 0,
    );

    expect(result.allowed, isTrue);
    expect(result.requiresPayment, isFalse);
    expect(result.freeRemaining, 2);
    expect(result.currentUsage, 0);
    expect(result.message, '무료 심층 분석이 2회 남아 있어요.');
  });

  test('payment required state can represent paid feature entry', () {
    final result = EntitlementCheckResult.paymentRequired(
      feature: PaidFeature.deepHealthAssessment,
      freeRemaining: 0,
    );

    expect(result.allowed, isFalse);
    expect(result.requiresPayment, isTrue);
    expect(result.freeRemaining, 0);
    expect(result.message, '무료 심층 분석을 모두 사용했어요.');
    expect(result.primaryCta, '결제하고 계속하기');
  });

  test('limit reached state can represent plant slot cap', () {
    final result = EntitlementCheckResult.limitReached(
      feature: PaidFeature.plantCharacterSlot,
      currentUsage: 3,
      limit: 3,
    );

    expect(result.allowed, isFalse);
    expect(result.requiresPayment, isTrue);
    expect(result.currentUsage, 3);
    expect(result.limit, 3);
    expect(result.message, '식물 캐릭터 한도에 도달했어요.');
    expect(result.primaryCta, '한도 늘리기');
  });
}
