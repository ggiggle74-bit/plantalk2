import '../models/entitlement_check_context.dart';
import '../models/entitlement_check_result.dart';
import '../models/paid_feature.dart';
import 'entitlement_gate_service.dart';

class LocalEntitlementGateService implements EntitlementGateService {
  const LocalEntitlementGateService({
    this.deepHealthAssessmentFreeRemaining = 1,
    this.plantCharacterLimit = 3,
  });

  final int deepHealthAssessmentFreeRemaining;
  final int plantCharacterLimit;

  @override
  Future<EntitlementCheckResult> check(
    PaidFeature feature, {
    EntitlementCheckContext context = const EntitlementCheckContext(),
  }) async {
    switch (feature) {
      case PaidFeature.deepHealthAssessment:
        return _checkDeepHealthAssessment(context);
      case PaidFeature.plantCharacterSlot:
        return _checkPlantCharacterSlot(context);
    }
  }

  EntitlementCheckResult _checkDeepHealthAssessment(
    EntitlementCheckContext context,
  ) {
    // TODO: Before paid launch, enforce this server-side before a deep health provider is called.
    final freeRemaining = deepHealthAssessmentFreeRemaining;
    if (freeRemaining > 0) {
      return EntitlementCheckResult.usageRemaining(
        feature: PaidFeature.deepHealthAssessment,
        freeRemaining: freeRemaining,
        currentUsage: context.currentUsage,
      );
    }

    return EntitlementCheckResult.paymentRequired(
      feature: PaidFeature.deepHealthAssessment,
      freeRemaining: freeRemaining,
      currentUsage: context.currentUsage,
    );
  }

  EntitlementCheckResult _checkPlantCharacterSlot(
    EntitlementCheckContext context,
  ) {
    // TODO: Before paid launch, enforce this server-side before plant insert.
    final currentCount = context.currentPlantCount ?? context.currentUsage ?? 0;
    if (currentCount < plantCharacterLimit) {
      return EntitlementCheckResult.allowed(
        feature: PaidFeature.plantCharacterSlot,
        currentUsage: currentCount,
        limit: plantCharacterLimit,
      );
    }

    return EntitlementCheckResult.limitReached(
      feature: PaidFeature.plantCharacterSlot,
      currentUsage: currentCount,
      limit: plantCharacterLimit,
    );
  }
}
