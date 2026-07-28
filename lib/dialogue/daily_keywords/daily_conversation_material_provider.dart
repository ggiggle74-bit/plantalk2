import 'daily_conversation_material_projector.dart';
import 'daily_keyword_source.dart';
import 'models/daily_conversation_material_context.dart';
import 'models/daily_keyword_source_request.dart';

class DailyConversationMaterialProvider {
  const DailyConversationMaterialProvider({
    required this.source,
    this.projector = const DailyConversationMaterialProjector(),
  });

  final DailyKeywordSource source;
  final DailyConversationMaterialProjector projector;

  Future<DailyConversationMaterialContext?> load({
    required DailyKeywordSourceRequest request,
  }) async {
    try {
      final context = await source.load(request);
      return projector.project(context: context, now: request.date);
    } catch (_) {
      return null;
    }
  }
}
