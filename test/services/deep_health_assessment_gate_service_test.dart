import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/monetization/models/entitlement_check_context.dart';
import 'package:plantalk2/monetization/models/entitlement_check_result.dart';
import 'package:plantalk2/monetization/models/paid_feature.dart';
import 'package:plantalk2/services/deep_health_assessment_gate_service.dart';

void main() {
  test('callback gate forwards the entitlement context', () async {
    const context = EntitlementCheckContext(currentUsage: 2);
    EntitlementCheckContext? receivedContext;
    final access = EntitlementCheckResult.usageRemaining(
      feature: PaidFeature.deepHealthAssessment,
      freeRemaining: 1,
      currentUsage: 2,
    );
    final expected = DeepHealthAssessmentAuthorization(
      access: access,
      reservationId: 'reservation-1',
    );
    final gate = CallbackDeepHealthAssessmentGateService(
      authorizeAndReserve: ({required context}) async {
        receivedContext = context;
        return expected;
      },
      commitReservation: ({required reservationId}) async {},
      releaseReservation: ({required reservationId}) async {},
    );

    final result = await gate.authorizeAndReserve(context: context);

    expect(receivedContext, same(context));
    expect(result, same(expected));
  });

  test('callback gate forwards commit and release reservation ids', () async {
    final events = <String>[];
    final gate = CallbackDeepHealthAssessmentGateService(
      authorizeAndReserve: ({required context}) async {
        return DeepHealthAssessmentAuthorization(
          access: EntitlementCheckResult.paymentRequired(
            feature: PaidFeature.deepHealthAssessment,
          ),
        );
      },
      commitReservation: ({required reservationId}) async {
        events.add('commit:$reservationId');
      },
      releaseReservation: ({required reservationId}) async {
        events.add('release:$reservationId');
      },
    );

    await gate.commitReservation(reservationId: 'reservation-1');
    await gate.releaseReservation(reservationId: 'reservation-2');

    expect(events, [
      'commit:reservation-1',
      'release:reservation-2',
    ]);
  });
}
