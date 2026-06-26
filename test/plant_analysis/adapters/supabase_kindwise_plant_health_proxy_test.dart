import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/kindwise_plant_health_adapter.dart';
import 'package:plantalk2/plant_analysis/adapters/supabase_kindwise_plant_health_proxy.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_exception.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';

void main() {
  test('invokes plant-health-assess with imageUrl only', () async {
    final calls = <Map<String, Object?>>[];
    final payload = _healthyPayload();
    final proxy = SupabaseKindwisePlantHealthProxy(
      invokeFunction: ({required functionName, required body}) async {
        calls.add({'functionName': functionName, 'body': body});
        return payload;
      },
    );

    final result = await proxy.invoke(
      imageUrl: '  https://example.test/storage/photo.jpg  ',
    );

    expect(result, same(payload));
    expect(calls, hasLength(1));
    expect(
      calls.single['functionName'],
      SupabaseKindwisePlantHealthProxy.defaultFunctionName,
    );
    expect(calls.single['body'], {
      'imageUrl': 'https://example.test/storage/photo.jpg',
    });
    expect(calls.single['body'], isNot(containsPair('plantId', anything)));
    expect(calls.single['body'], isNot(containsPair('plantName', anything)));
    expect(calls.single['body'], isNot(containsPair('userId', anything)));
    expect(calls.single['body'], isNot(containsPair('metadata', anything)));
  });

  test('rejects empty imageUrl before invoking Supabase', () async {
    for (final imageUrl in const ['', '   ']) {
      var callCount = 0;
      final proxy = SupabaseKindwisePlantHealthProxy(
        invokeFunction: ({required functionName, required body}) async {
          callCount += 1;
          return _healthyPayload();
        },
      );

      await expectLater(
        proxy.invoke(imageUrl: imageUrl),
        throwsA(
          isA<PlantAnalysisException>().having(
            (error) => error.message,
            'message',
            contains('requires an imageUrl'),
          ),
        ),
      );
      expect(callCount, 0);
    }
  });

  test('throws analysis exception when response is null', () async {
    final proxy = SupabaseKindwisePlantHealthProxy(
      invokeFunction: ({required functionName, required body}) async => null,
    );

    await expectLater(
      proxy.invoke(imageUrl: 'https://example.test/photo.jpg'),
      throwsA(
        isA<PlantAnalysisException>().having(
          (error) => error.message,
          'message',
          contains('returned no payload'),
        ),
      ),
    );
  });

  test('throws analysis exception when response is not a map', () async {
    for (final response in const ['not-json-object', [], 42, true]) {
      final proxy = SupabaseKindwisePlantHealthProxy(
        invokeFunction: ({required functionName, required body}) async =>
            response,
      );

      await expectLater(
        proxy.invoke(imageUrl: 'https://example.test/photo.jpg'),
        throwsA(
          isA<PlantAnalysisException>().having(
            (error) => error.message,
            'message',
            contains('non-object payload'),
          ),
        ),
      );
    }
  });

  test('wraps invocation failure clearly', () async {
    final invocationError = StateError('function failed');
    final proxy = SupabaseKindwisePlantHealthProxy(
      invokeFunction: ({required functionName, required body}) async {
        throw invocationError;
      },
    );

    await expectLater(
      proxy.invoke(imageUrl: 'https://example.test/photo.jpg'),
      throwsA(
        isA<PlantAnalysisException>()
            .having(
              (error) => error.message,
              'message',
              contains('invocation failed'),
            )
            .having((error) => error.cause, 'cause', same(invocationError)),
      ),
    );
  });

  test('works with KindwisePlantHealthAdapter', () async {
    final calls = <Map<String, Object?>>[];
    final proxy = SupabaseKindwisePlantHealthProxy(
      invokeFunction: ({required functionName, required body}) async {
        calls.add({'functionName': functionName, 'body': body});
        return _healthyPayload();
      },
    );
    final adapter = KindwisePlantHealthAdapter(invokeProxy: proxy.invoke);

    final result = await adapter.analyze(
      const PlantAnalysisInput(
        plantId: 'private-plant-id',
        analysisType: PlantAnalysisTypes.conditionCheck,
        speciesKey: 'private-species-key',
        speciesDisplayName: 'Private plant',
        imagePath: r'C:\private\photo.jpg',
        imageUrl: 'https://example.test/private-photo.jpg',
        userPrompt: 'private prompt',
        metadata: {'private': 'metadata'},
      ),
    );

    expect(result.analysisType, PlantAnalysisTypes.conditionCheck);
    expect(result.rawPayload, isEmpty);
    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.healthOk,
    );
    expect(calls, hasLength(1));
    expect(calls.single['body'], {
      'imageUrl': 'https://example.test/private-photo.jpg',
    });
  });
}

Map<String, dynamic> _healthyPayload() {
  return {
    'access_token': 'fake-kindwise-token',
    'created': 1782057600,
    'status': 'COMPLETED',
    'result': {
      'is_healthy': {'binary': true, 'probability': 0.94, 'threshold': 0.63},
      'disease': {'suggestions': const []},
    },
  };
}
