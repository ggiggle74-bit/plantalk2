import '../monetization/models/entitlement_check_context.dart';
import '../monetization/models/entitlement_check_result.dart';

typedef AuthorizeAndReserveDeepHealthAssessmentCallback =
    Future<EntitlementCheckResult> Function({
      required EntitlementCheckContext context,
    });

abstract class DeepHealthAssessmentGateService {
  Future<EntitlementCheckResult> authorizeAndReserve({
    EntitlementCheckContext context = const EntitlementCheckContext(),
  });
}

class CallbackDeepHealthAssessmentGateService
    implements DeepHealthAssessmentGateService {
  const CallbackDeepHealthAssessmentGateService({
    required AuthorizeAndReserveDeepHealthAssessmentCallback
    authorizeAndReserve,
  }) : _authorizeAndReserve = authorizeAndReserve;

  final AuthorizeAndReserveDeepHealthAssessmentCallback _authorizeAndReserve;

  @override
  Future<EntitlementCheckResult> authorizeAndReserve({
    EntitlementCheckContext context = const EntitlementCheckContext(),
  }) {
    return _authorizeAndReserve(context: context);
  }
}
