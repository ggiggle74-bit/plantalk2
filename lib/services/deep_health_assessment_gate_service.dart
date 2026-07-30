import '../monetization/models/entitlement_check_context.dart';
import '../monetization/models/entitlement_check_result.dart';

class DeepHealthAssessmentAuthorization {
  const DeepHealthAssessmentAuthorization({
    required this.access,
    this.reservationId,
  });

  final EntitlementCheckResult access;
  final String? reservationId;
}

typedef AuthorizeAndReserveDeepHealthAssessmentCallback =
    Future<DeepHealthAssessmentAuthorization> Function({
      required EntitlementCheckContext context,
    });
typedef UpdateDeepHealthAssessmentReservationCallback =
    Future<void> Function({required String reservationId});

abstract class DeepHealthAssessmentGateService {
  Future<DeepHealthAssessmentAuthorization> authorizeAndReserve({
    EntitlementCheckContext context = const EntitlementCheckContext(),
  });

  Future<void> commitReservation({required String reservationId});

  Future<void> releaseReservation({required String reservationId});
}

class CallbackDeepHealthAssessmentGateService
    implements DeepHealthAssessmentGateService {
  const CallbackDeepHealthAssessmentGateService({
    required AuthorizeAndReserveDeepHealthAssessmentCallback
    authorizeAndReserve,
    required UpdateDeepHealthAssessmentReservationCallback commitReservation,
    required UpdateDeepHealthAssessmentReservationCallback releaseReservation,
  }) : _authorizeAndReserve = authorizeAndReserve,
       _commitReservation = commitReservation,
       _releaseReservation = releaseReservation;

  final AuthorizeAndReserveDeepHealthAssessmentCallback _authorizeAndReserve;
  final UpdateDeepHealthAssessmentReservationCallback _commitReservation;
  final UpdateDeepHealthAssessmentReservationCallback _releaseReservation;

  @override
  Future<DeepHealthAssessmentAuthorization> authorizeAndReserve({
    EntitlementCheckContext context = const EntitlementCheckContext(),
  }) {
    return _authorizeAndReserve(context: context);
  }

  @override
  Future<void> commitReservation({required String reservationId}) {
    return _commitReservation(reservationId: reservationId);
  }

  @override
  Future<void> releaseReservation({required String reservationId}) {
    return _releaseReservation(reservationId: reservationId);
  }
}
