import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plant_analysis_exception.dart';

typedef InvokeSupabaseKindwisePlantHealthFunctionCallback =
    Future<Object?> Function({
      required String functionName,
      required Map<String, Object?> body,
    });

class SupabaseKindwisePlantHealthProxy {
  const SupabaseKindwisePlantHealthProxy({
    InvokeSupabaseKindwisePlantHealthFunctionCallback? invokeFunction,
    this.functionName = defaultFunctionName,
  }) : _invokeFunction = invokeFunction;

  static const defaultFunctionName = 'plant-health-assess';

  final InvokeSupabaseKindwisePlantHealthFunctionCallback? _invokeFunction;
  final String functionName;

  Future<Map<String, dynamic>> invoke({
    required String imageUrl,
    String? reservationId,
  }) async {
    final normalizedFunctionName = _validatedFunctionName(functionName);
    final normalizedImageUrl = _validatedImageUrl(imageUrl);
    final normalizedReservationId = _optionalReservationId(reservationId);
    final invokeFunction = _invokeFunction ?? _invokeSupabaseFunction;

    final Object? response;
    try {
      response = await invokeFunction(
        functionName: normalizedFunctionName,
        body: {
          'imageUrl': normalizedImageUrl,
          if (normalizedReservationId != null)
            'reservationId': normalizedReservationId,
        },
      );
    } catch (error) {
      throw PlantAnalysisException(
        'Kindwise plant health Supabase function invocation failed.',
        cause: error,
      );
    }

    return _validatedResponseMap(response);
  }

  static Future<Object?> _invokeSupabaseFunction({
    required String functionName,
    required Map<String, Object?> body,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      functionName,
      body: body,
    );

    return response.data;
  }

  static String _validatedFunctionName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      throw const PlantAnalysisException(
        'Kindwise plant health function name is required.',
      );
    }

    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(name)) {
      throw const PlantAnalysisException(
        'Kindwise plant health function name must be a Supabase Function slug.',
      );
    }

    return name;
  }

  static String _validatedImageUrl(String value) {
    final imageUrl = value.trim();
    if (imageUrl.isEmpty) {
      throw const PlantAnalysisException(
        'Kindwise plant health proxy requires an imageUrl.',
      );
    }

    return imageUrl;
  }

  static String? _optionalReservationId(String? value) {
    if (value == null) return null;
    final reservationId = value.trim();
    if (reservationId.isEmpty) {
      throw const PlantAnalysisException(
        'Kindwise plant health reservationId must not be blank.',
      );
    }
    return reservationId;
  }

  static Map<String, dynamic> _validatedResponseMap(Object? response) {
    if (response == null) {
      throw const PlantAnalysisException(
        'Kindwise plant health Supabase function returned no payload.',
      );
    }
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw const PlantAnalysisException(
      'Kindwise plant health Supabase function returned a non-object payload.',
    );
  }
}
