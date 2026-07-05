import 'paid_feature.dart';

class EntitlementCheckResult {
  const EntitlementCheckResult({
    required this.feature,
    required this.allowed,
    required this.requiresPayment,
    required this.title,
    required this.message,
    required this.primaryCta,
    required this.secondaryCta,
    this.freeRemaining,
    this.currentUsage,
    this.limit,
    this.resetAt,
  });

  factory EntitlementCheckResult.allowed({
    required PaidFeature feature,
    String? title,
    String? message,
    String primaryCta = '계속하기',
    String secondaryCta = '취소',
    int? currentUsage,
    int? limit,
    DateTime? resetAt,
  }) {
    return EntitlementCheckResult(
      feature: feature,
      allowed: true,
      requiresPayment: false,
      currentUsage: currentUsage,
      limit: limit,
      resetAt: resetAt,
      title: title ?? feature.title,
      message: message ?? _allowedMessage(feature),
      primaryCta: primaryCta,
      secondaryCta: secondaryCta,
    );
  }

  factory EntitlementCheckResult.usageRemaining({
    required PaidFeature feature,
    required int freeRemaining,
    String? title,
    String? message,
    String primaryCta = '계속하기',
    String secondaryCta = '취소',
    int? currentUsage,
    int? limit,
    DateTime? resetAt,
  }) {
    return EntitlementCheckResult(
      feature: feature,
      allowed: true,
      requiresPayment: false,
      freeRemaining: freeRemaining,
      currentUsage: currentUsage,
      limit: limit,
      resetAt: resetAt,
      title: title ?? feature.title,
      message: message ?? _usageRemainingMessage(feature, freeRemaining),
      primaryCta: primaryCta,
      secondaryCta: secondaryCta,
    );
  }

  factory EntitlementCheckResult.paymentRequired({
    required PaidFeature feature,
    String? title,
    String? message,
    String primaryCta = '결제하고 계속하기',
    String secondaryCta = '취소',
    int? freeRemaining,
    int? currentUsage,
    int? limit,
    DateTime? resetAt,
  }) {
    return EntitlementCheckResult(
      feature: feature,
      allowed: false,
      requiresPayment: true,
      freeRemaining: freeRemaining,
      currentUsage: currentUsage,
      limit: limit,
      resetAt: resetAt,
      title: title ?? feature.title,
      message: message ?? _paymentRequiredMessage(feature),
      primaryCta: primaryCta,
      secondaryCta: secondaryCta,
    );
  }

  factory EntitlementCheckResult.limitReached({
    required PaidFeature feature,
    String? title,
    String? message,
    String primaryCta = '한도 늘리기',
    String secondaryCta = '취소',
    int? currentUsage,
    int? limit,
    DateTime? resetAt,
  }) {
    return EntitlementCheckResult(
      feature: feature,
      allowed: false,
      requiresPayment: true,
      currentUsage: currentUsage,
      limit: limit,
      resetAt: resetAt,
      title: title ?? feature.title,
      message: message ?? _limitReachedMessage(feature),
      primaryCta: primaryCta,
      secondaryCta: secondaryCta,
    );
  }

  final PaidFeature feature;
  final bool allowed;
  final bool requiresPayment;
  final int? freeRemaining;
  final int? currentUsage;
  final int? limit;
  final DateTime? resetAt;
  final String title;
  final String message;
  final String primaryCta;
  final String secondaryCta;

  static String _allowedMessage(PaidFeature feature) {
    switch (feature) {
      case PaidFeature.deepHealthAssessment:
        return '심층 분석을 진행할 수 있어요.';
      case PaidFeature.plantCharacterSlot:
        return '새 식물 캐릭터를 만들 수 있어요.';
    }
  }

  static String _usageRemainingMessage(PaidFeature feature, int remaining) {
    switch (feature) {
      case PaidFeature.deepHealthAssessment:
        return '무료 심층 분석이 $remaining회 남아 있어요.';
      case PaidFeature.plantCharacterSlot:
        return '새 식물 캐릭터를 만들 수 있어요.';
    }
  }

  static String _paymentRequiredMessage(PaidFeature feature) {
    switch (feature) {
      case PaidFeature.deepHealthAssessment:
        return '무료 심층 분석을 모두 사용했어요.';
      case PaidFeature.plantCharacterSlot:
        return '식물 캐릭터 슬롯을 추가하려면 결제가 필요해요.';
    }
  }

  static String _limitReachedMessage(PaidFeature feature) {
    switch (feature) {
      case PaidFeature.deepHealthAssessment:
        return '무료 심층 분석을 모두 사용했어요.';
      case PaidFeature.plantCharacterSlot:
        return '식물 캐릭터 한도에 도달했어요.';
    }
  }
}
