import '../models/paid_feature.dart';

abstract class ExternalBillingGateway {
  Future<void> openBillingPortal();

  Future<void> startPurchase(PaidFeature feature);
}
