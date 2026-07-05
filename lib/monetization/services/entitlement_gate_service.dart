import '../models/entitlement_check_context.dart';
import '../models/entitlement_check_result.dart';
import '../models/paid_feature.dart';

abstract class EntitlementGateService {
  Future<EntitlementCheckResult> check(
    PaidFeature feature, {
    EntitlementCheckContext context = const EntitlementCheckContext(),
  });
}
