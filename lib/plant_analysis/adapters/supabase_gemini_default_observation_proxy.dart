import 'package:supabase_flutter/supabase_flutter.dart';

typedef InvokeSupabaseGeminiDefaultObservationFunctionCallback =
    Future<Object?> Function({
      required String functionName,
      required Map<String, Object?> body,
    });

class SupabaseGeminiDefaultObservationProxy {
  const SupabaseGeminiDefaultObservationProxy({
    InvokeSupabaseGeminiDefaultObservationFunctionCallback? invokeFunction,
    this.functionName = defaultFunctionName,
  }) : _invokeFunction = invokeFunction;

  static const defaultFunctionName = 'gemini-default-observe';

  final InvokeSupabaseGeminiDefaultObservationFunctionCallback? _invokeFunction;
  final String functionName;

  Future<Object?> invoke({required String imageUrl}) async {
    final normalizedFunctionName = _validatedFunctionName(functionName);
    final normalizedImageUrl = _validatedImageUrl(imageUrl);
    final invokeFunction = _invokeFunction ?? _invokeSupabaseFunction;

    return invokeFunction(
      functionName: normalizedFunctionName,
      body: {'imageUrl': normalizedImageUrl},
    );
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
      throw StateError('Gemini default observation function name is required.');
    }

    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(name)) {
      throw StateError(
        'Gemini default observation function name must be a Supabase Function slug.',
      );
    }

    return name;
  }

  static String _validatedImageUrl(String value) {
    final imageUrl = value.trim();
    if (imageUrl.isEmpty) {
      throw StateError(
        'Gemini default observation proxy requires an imageUrl.',
      );
    }

    final uri = Uri.tryParse(imageUrl);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        !uri.hasScheme ||
        (scheme != 'http' && scheme != 'https') ||
        uri.host.trim().isEmpty) {
      throw StateError(
        'Gemini default observation proxy requires an absolute HTTP or HTTPS imageUrl.',
      );
    }

    return imageUrl;
  }
}
