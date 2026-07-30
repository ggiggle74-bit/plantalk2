import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/monetization/models/entitlement_check_context.dart';
import 'package:plantalk2/monetization/models/paid_feature.dart';
import 'package:plantalk2/services/supabase_deep_health_assessment_gate_service.dart';

void main() {
  test('reserves from server and ignores client usage context', () async {
    final calls = <Map<String, Object?>>[];
    final gate = SupabaseDeepHealthAssessmentGateService(
      invokeRpc: ({required functionName, required params}) async {
        calls.add({'functionName': functionName, 'params': params});
        return [
          {
            'allowed': true,
            'requires_payment': false,
            'reservation_id': 'reservation-1',
            'free_remaining': 1,
            'current_usage': 0,
            'usage_limit': 1,
          },
        ];
      },
    );

    final result = await gate.authorizeAndReserve(
      context: const EntitlementCheckContext(currentUsage: 999),
    );

    expect(calls, [
      {
        'functionName':
            SupabaseDeepHealthAssessmentGateService.reserveFunctionName,
        'params': const <String, Object?>{},
      },
    ]);
    expect(result.reservationId, 'reservation-1');
    expect(result.access.feature, PaidFeature.deepHealthAssessment);
    expect(result.access.allowed, isTrue);
    expect(result.access.requiresPayment, isFalse);
    expect(result.access.freeRemaining, 1);
    expect(result.access.currentUsage, 0);
    expect(result.access.limit, 1);
  });

  test('maps exhausted server quota to payment required', () async {
    final gate = SupabaseDeepHealthAssessmentGateService(
      invokeRpc: ({required functionName, required params}) async {
        return {
          'allowed': false,
          'requires_payment': true,
          'reservation_id': null,
          'free_remaining': 0,
          'current_usage': 1,
          'usage_limit': 1,
        };
      },
    );

    final result = await gate.authorizeAndReserve();

    expect(result.reservationId, isNull);
    expect(result.access.allowed, isFalse);
    expect(result.access.requiresPayment, isTrue);
    expect(result.access.freeRemaining, 0);
    expect(result.access.currentUsage, 1);
    expect(result.access.limit, 1);
  });

  test('rejects inconsistent or malformed reserve decisions', () async {
    final payloads = <Object?>[
      const [],
      const [
        {
          'allowed': true,
          'requires_payment': false,
          'reservation_id': null,
          'free_remaining': 1,
          'current_usage': 0,
          'usage_limit': 1,
        },
      ],
      const [
        {
          'allowed': false,
          'requires_payment': false,
          'reservation_id': null,
          'free_remaining': 0,
          'current_usage': 1,
          'usage_limit': 1,
        },
      ],
      const [
        {
          'allowed': true,
          'requires_payment': false,
          'reservation_id': 'reservation-1',
          'free_remaining': -1,
          'current_usage': 0,
          'usage_limit': 1,
        },
      ],
    ];

    for (final payload in payloads) {
      final gate = SupabaseDeepHealthAssessmentGateService(
        invokeRpc: ({required functionName, required params}) async => payload,
      );

      await expectLater(
        gate.authorizeAndReserve(),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('commits reservation through the authenticated RPC contract', () async {
    final calls = <Map<String, Object?>>[];
    final gate = SupabaseDeepHealthAssessmentGateService(
      invokeRpc: ({required functionName, required params}) async {
        calls.add({'functionName': functionName, 'params': params});
        return [
          {
            'reservation_id': 'reservation-1',
            'reservation_status': 'committed',
          },
        ];
      },
    );

    await gate.commitReservation(reservationId: ' reservation-1 ');

    expect(calls.single, {
      'functionName':
          SupabaseDeepHealthAssessmentGateService.commitFunctionName,
      'params': {'p_reservation_id': 'reservation-1'},
    });
  });

  test(
    'commit fails closed when server does not confirm committed state',
    () async {
      for (final status in const ['reserved', 'released', 'expired']) {
        final gate = SupabaseDeepHealthAssessmentGateService(
          invokeRpc: ({required functionName, required params}) async => [
            {
              'reservation_id': 'reservation-1',
              'reservation_status': status,
            },
          ],
        );

        await expectLater(
          gate.commitReservation(reservationId: 'reservation-1'),
          throwsA(isA<StateError>()),
        );
      }
    },
  );

  test(
    'release accepts released, expired, and already committed states',
    () async {
      for (final status in const ['released', 'expired', 'committed']) {
        final gate = SupabaseDeepHealthAssessmentGateService(
          invokeRpc: ({required functionName, required params}) async => [
            {
              'reservation_id': 'reservation-1',
              'reservation_status': status,
            },
          ],
        );

        await gate.releaseReservation(reservationId: 'reservation-1');
      }
    },
  );

  test('rejects blank reservation ids before calling RPC', () async {
    var callCount = 0;
    final gate = SupabaseDeepHealthAssessmentGateService(
      invokeRpc: ({required functionName, required params}) async {
        callCount += 1;
        return null;
      },
    );

    await expectLater(
      gate.commitReservation(reservationId: '  '),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      gate.releaseReservation(reservationId: ''),
      throwsA(isA<ArgumentError>()),
    );
    expect(callCount, 0);
  });
}
