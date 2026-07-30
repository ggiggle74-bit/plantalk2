import 'package:supabase_flutter/supabase_flutter.dart';

import '../monetization/models/entitlement_check_context.dart';
import '../monetization/models/entitlement_check_result.dart';
import '../monetization/models/paid_feature.dart';
import 'deep_health_assessment_gate_service.dart';

typedef InvokeDeepHealthAssessmentQuotaRpcCallback =
    Future<Object?> Function({
      required String functionName,
      required Map<String, Object?> params,
    });

class SupabaseDeepHealthAssessmentGateService
    implements DeepHealthAssessmentGateService {
  SupabaseDeepHealthAssessmentGateService({
    InvokeDeepHealthAssessmentQuotaRpcCallback? invokeRpc,
  }) : _invokeRpc = invokeRpc ?? _invokeSupabaseRpc;

  static const reserveFunctionName =
      'reserve_deep_health_assessment_usage';
  static const commitFunctionName =
      'commit_deep_health_assessment_usage';
  static const releaseFunctionName =
      'release_deep_health_assessment_usage';

  final InvokeDeepHealthAssessmentQuotaRpcCallback _invokeRpc;

  @override
  Future<DeepHealthAssessmentAuthorization> authorizeAndReserve({
    EntitlementCheckContext context = const EntitlementCheckContext(),
  }) async {
    final response = await _invokeRpc(
      functionName: reserveFunctionName,
      params: const {},
    );
    final row = _singleRow(response, operation: 'reserve');
    final allowed = _requiredBool(row, 'allowed');
    final requiresPayment = _requiredBool(row, 'requires_payment');
    final reservationId = _optionalText(row, 'reservation_id');
    final freeRemaining = _requiredNonNegativeInt(row, 'free_remaining');
    final currentUsage = _requiredNonNegativeInt(row, 'current_usage');
    final limit = _requiredNonNegativeInt(row, 'usage_limit');

    if (allowed == requiresPayment ||
        allowed != (reservationId != null) ||
        currentUsage > limit ||
        freeRemaining > limit) {
      throw const FormatException(
        'Deep health quota reserve RPC returned an inconsistent decision.',
      );
    }

    final access = allowed
        ? EntitlementCheckResult.usageRemaining(
            feature: PaidFeature.deepHealthAssessment,
            freeRemaining: freeRemaining,
            currentUsage: currentUsage,
            limit: limit,
          )
        : EntitlementCheckResult.paymentRequired(
            feature: PaidFeature.deepHealthAssessment,
            freeRemaining: freeRemaining,
            currentUsage: currentUsage,
            limit: limit,
          );

    return DeepHealthAssessmentAuthorization(
      access: access,
      reservationId: reservationId,
    );
  }

  @override
  Future<void> commitReservation({required String reservationId}) async {
    final normalizedId = _requiredReservationId(reservationId);
    final response = await _invokeRpc(
      functionName: commitFunctionName,
      params: {'p_reservation_id': normalizedId},
    );
    final row = _singleRow(response, operation: 'commit');
    final returnedId = _requiredText(row, 'reservation_id');
    final status = _requiredText(row, 'reservation_status');

    if (returnedId != normalizedId || status != 'committed') {
      throw StateError(
        'Deep health quota reservation was not committed.',
      );
    }
  }

  @override
  Future<void> releaseReservation({required String reservationId}) async {
    final normalizedId = _requiredReservationId(reservationId);
    final response = await _invokeRpc(
      functionName: releaseFunctionName,
      params: {'p_reservation_id': normalizedId},
    );
    final row = _singleRow(response, operation: 'release');
    final returnedId = _requiredText(row, 'reservation_id');
    final status = _requiredText(row, 'reservation_status');

    if (returnedId != normalizedId ||
        !const {'released', 'expired', 'committed'}.contains(status)) {
      throw StateError(
        'Deep health quota reservation was not safely released.',
      );
    }
  }

  static Future<Object?> _invokeSupabaseRpc({
    required String functionName,
    required Map<String, Object?> params,
  }) {
    return Supabase.instance.client.rpc(functionName, params: params);
  }

  static Map<String, Object?> _singleRow(
    Object? response, {
    required String operation,
  }) {
    Object? candidate = response;
    if (candidate is List) {
      if (candidate.length != 1) {
        throw FormatException(
          'Deep health quota $operation RPC must return exactly one row.',
        );
      }
      candidate = candidate.single;
    }

    if (candidate is Map) {
      return Map<String, Object?>.from(candidate);
    }

    throw FormatException(
      'Deep health quota $operation RPC returned a non-object payload.',
    );
  }

  static bool _requiredBool(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is bool) return value;
    throw FormatException('Deep health quota RPC field $key must be boolean.');
  }

  static int _requiredNonNegativeInt(
    Map<String, Object?> row,
    String key,
  ) {
    final value = row[key];
    if (value is int && value >= 0) return value;
    throw FormatException(
      'Deep health quota RPC field $key must be a non-negative integer.',
    );
  }

  static String _requiredText(Map<String, Object?> row, String key) {
    final value = _optionalText(row, key);
    if (value != null) return value;
    throw FormatException('Deep health quota RPC field $key is required.');
  }

  static String? _optionalText(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Deep health quota RPC field $key must be non-empty text.',
      );
    }
    return value.trim();
  }

  static String _requiredReservationId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'reservationId',
        'Deep health quota reservation id is required.',
      );
    }
    return normalized;
  }
}
