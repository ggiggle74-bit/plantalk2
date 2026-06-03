import '../dialogue/chat_panel.dart';

typedef PlantChatStateUpdater = void Function(void Function());
typedef PlantMessageUpdater =
    Future<void> Function(Map<String, dynamic>, String);
typedef PlantFriendshipUpdater =
    Future<void> Function(Map<String, dynamic>, int, String);

class PlantChatResultHandler {
  const PlantChatResultHandler();

  Future<void> updatePlantAfterChat({
    required bool isMounted,
    required Map<String, dynamic> plant,
    required ChatPanelResult chatResult,
    required PlantChatStateUpdater updateState,
    required PlantMessageUpdater updatePlantMessage,
    required PlantFriendshipUpdater updatePlantFriendship,
  }) async {
    if (!isMounted) return;

    final latestReply = chatResult.latestPlantReply;
    final currentFriendship = plant['friendship'] is int
        ? plant['friendship'] as int
        : 0;
    final updatedFriendship = currentFriendship + chatResult.userMessageCount;
    final mood = plant['mood']?.toString() ?? '\ubcf4\ud1b5';

    updateState(() {
      if (latestReply != null) {
        plant['message'] = latestReply;
      }
      plant['friendship'] = updatedFriendship;
    });

    if (latestReply != null) {
      await updatePlantMessage(plant, latestReply);
    }

    await updatePlantFriendship(plant, updatedFriendship, mood);
  }
}
