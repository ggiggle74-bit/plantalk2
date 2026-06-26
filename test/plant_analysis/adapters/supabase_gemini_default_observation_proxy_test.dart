import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/plant_analysis/adapters/gemini_default_state_observation_adapter.dart';
import 'package:plantalk2/plant_analysis/adapters/supabase_gemini_default_observation_proxy.dart';
import 'package:plantalk2/plant_analysis/models/normalized_plant_event.dart';
import 'package:plantalk2/plant_analysis/models/plant_analysis_input.dart';

void main() {
  test('invokes the default Supabase function with imageUrl only', () async {
    final calls = <Map<String, Object?>>[];
    final payload = _stablePayload();
    final proxy = SupabaseGeminiDefaultObservationProxy(
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
      SupabaseGeminiDefaultObservationProxy.defaultFunctionName,
    );
    expect(calls.single['body'], {
      'imageUrl': 'https://example.test/storage/photo.jpg',
    });
    expect(calls.single['body'], isNot(containsPair('plantId', anything)));
    expect(calls.single['body'], isNot(containsPair('metadata', anything)));
  });

  test('supports a configured Supabase function name', () async {
    String? receivedFunctionName;
    final proxy = SupabaseGeminiDefaultObservationProxy(
      functionName: 'gemini-default-observe-dev',
      invokeFunction: ({required functionName, required body}) async {
        receivedFunctionName = functionName;
        return _stablePayload();
      },
    );

    await proxy.invoke(imageUrl: 'https://example.test/photo.jpg');

    expect(receivedFunctionName, 'gemini-default-observe-dev');
  });

  test('rejects invalid function names without invoking Supabase', () async {
    for (final functionName in const [
      '',
      '   ',
      'GeminiDefaultObserve',
      'gemini_default_observe',
      '../gemini-default-observe',
      'gemini/default/observe',
      '-gemini-default-observe',
      'gemini-default-observe-',
    ]) {
      var callCount = 0;
      final proxy = SupabaseGeminiDefaultObservationProxy(
        functionName: functionName,
        invokeFunction: ({required functionName, required body}) async {
          callCount += 1;
          return _stablePayload();
        },
      );

      await expectLater(
        proxy.invoke(imageUrl: 'https://example.test/photo.jpg'),
        throwsA(isA<StateError>()),
      );
      expect(callCount, 0);
    }
  });

  test('rejects invalid image URLs without invoking Supabase', () async {
    for (final imageUrl in const [
      '',
      '   ',
      'relative/photo.jpg',
      r'C:\photos\plant.jpg',
      'file:///tmp/plant.jpg',
      'data:image/jpeg;base64,fake',
      'ftp://example.test/plant.jpg',
      'https:///missing-host.jpg',
    ]) {
      var callCount = 0;
      final proxy = SupabaseGeminiDefaultObservationProxy(
        invokeFunction: ({required functionName, required body}) async {
          callCount += 1;
          return _stablePayload();
        },
      );

      await expectLater(
        proxy.invoke(imageUrl: imageUrl),
        throwsA(isA<StateError>()),
      );
      expect(callCount, 0);
    }
  });

  test('accepts HTTP and HTTPS image URLs', () async {
    for (final imageUrl in const [
      'http://localhost:54321/storage/v1/object/public/plant-photos/photo.jpg',
      'https://example.test/photo.jpg',
    ]) {
      String? receivedImageUrl;
      final proxy = SupabaseGeminiDefaultObservationProxy(
        invokeFunction: ({required functionName, required body}) async {
          receivedImageUrl = body['imageUrl']?.toString();
          return _stablePayload();
        },
      );

      await proxy.invoke(imageUrl: '  $imageUrl  ');

      expect(receivedImageUrl, imageUrl);
    }
  });

  test('works with GeminiDefaultStateObservationAdapter', () async {
    final calls = <Map<String, Object?>>[];
    final proxy = SupabaseGeminiDefaultObservationProxy(
      invokeFunction: ({required functionName, required body}) async {
        calls.add({'functionName': functionName, 'body': body});
        return _stablePayload();
      },
    );
    final adapter = GeminiDefaultStateObservationAdapter(
      invokeProxy: proxy.invoke,
    );

    final result = await adapter.analyze(
      const PlantAnalysisInput(
        plantId: 'private-plant-id',
        analysisType: PlantAnalysisTypes.defaultObservation,
        speciesKey: 'private-species-key',
        speciesDisplayName: 'Private plant',
        imagePath: r'C:\private\photo.jpg',
        imageUrl: 'https://example.test/private-photo.jpg',
        userPrompt: 'private prompt',
        metadata: {'private': 'metadata'},
      ),
    );

    expect(
      result.conditionEventHints.single.eventType,
      PlantAnalysisEventTypes.appearanceStable,
    );
    expect(result.rawPayload, isEmpty);
    expect(calls, hasLength(1));
    expect(calls.single['body'], {
      'imageUrl': 'https://example.test/private-photo.jpg',
    });
  });

  test(
    'passes malformed gateway payload through for parser degradation',
    () async {
      final proxy = SupabaseGeminiDefaultObservationProxy(
        invokeFunction: ({required functionName, required body}) async => {
          'image_quality': 'usable',
          'observation_state': 'stable_appearance',
          'evidence_tags': ['stable_foliage', 'unapproved_model_tag'],
        },
      );
      final adapter = GeminiDefaultStateObservationAdapter(
        invokeProxy: proxy.invoke,
      );

      final result = await adapter.analyze(
        const PlantAnalysisInput(
          plantId: 'plant-1',
          analysisType: PlantAnalysisTypes.defaultObservation,
          imageUrl: 'https://example.test/photo.jpg',
        ),
      );

      expect(
        result.conditionEventHints.single.eventType,
        PlantAnalysisEventTypes.conditionUncertain,
      );
    },
  );

  test('propagates the identical Supabase invocation failure object', () async {
    final proxyError = StateError('Supabase function failed');
    final proxy = SupabaseGeminiDefaultObservationProxy(
      invokeFunction: ({required functionName, required body}) async {
        throw proxyError;
      },
    );

    await expectLater(
      proxy.invoke(imageUrl: 'https://example.test/photo.jpg'),
      throwsA(same(proxyError)),
    );
  });
}

Map<String, dynamic> _stablePayload() {
  return {
    'observation_id': 'observation-1',
    'observed_at': '2026-06-24T01:02:03Z',
    'image_quality': 'usable',
    'observation_state': 'stable_appearance',
    'evidence_tags': ['stable_foliage'],
    'summary_ko': '이 식물은 완벽하게 건강합니다.',
    'diagnosis': '확정 진단',
    'recommended_action': '약제를 사용하세요.',
    'confidence': 0.99,
  };
}
