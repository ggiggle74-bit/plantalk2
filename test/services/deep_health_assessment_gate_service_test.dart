import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/monetization/models/entitlement_check_context.dart';
import 'package:plantalk2/monetization/models/entitlement_check_result.dart';
import 'package:plantalk2/monetization/models/paid_feature.dart';
import 'package:plantalk2/services/deep_health_assessment_gate_service.dart';

void main() {
  test('callback gate forwards the entitlement context', () async {
    const context = EntitlementCheckContext(currentUsage: 2);
    EntitlementCheckContext? receivedContext;
    final expected = EntitlementCheckResult.usageRemaining(
      feature: PaidFeature.deepHealthAssessment,
      freeRemaining: 1,
      currentUsage: 2,
    );
    final gate = CallbackDeepHealthAssessmentGateService(
      authorizeAndReserve: ({required context}) async {
        receivedContext = context;
        return expected;
      },
    );

    final result = await gate.authorizeAndReserve(context: context);

    expect(receivedContext, same(context));
    expect(result, same(expected));
  });
}
