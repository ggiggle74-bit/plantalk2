import '../services/plant_condition_analysis_service.dart';

class LatestConditionMemory {
  const LatestConditionMemory({
    this.message,
    this.eventType,
  });

  final String? message;
  final String? eventType;

  static LatestConditionMemory? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;

    final trimmedMessage = row['message']?.toString().trim();
    final message = trimmedMessage == null || trimmedMessage.isEmpty
        ? null
        : trimmedMessage;
    final eventType = PlantConditionEventTypes.normalize(
      row['event_type']?.toString(),
    );

    if (message == null && eventType == null) return null;

    return LatestConditionMemory(
      message: message,
      eventType: eventType,
    );
  }
}
