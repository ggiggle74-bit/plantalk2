import '../services/plant_condition_analysis_service.dart';

class LatestConditionMemory {
  const LatestConditionMemory({
    this.message,
    this.eventType,
    this.checkedAt,
  });

  static const conversationFreshnessWindow = Duration(days: 7);

  final String? message;
  final String? eventType;
  final DateTime? checkedAt;

  bool isFreshAt(
    DateTime now, {
    Duration maximumAge = conversationFreshnessWindow,
  }) {
    if (maximumAge.isNegative) {
      throw ArgumentError.value(maximumAge, 'maximumAge', 'must not be negative');
    }

    final timestamp = checkedAt;
    if (timestamp == null) {
      return true;
    }

    final utcNow = now.toUtc();
    final utcTimestamp = timestamp.toUtc();
    if (utcTimestamp.isAfter(utcNow)) {
      return false;
    }

    return !utcTimestamp.isBefore(utcNow.subtract(maximumAge));
  }

  static LatestConditionMemory? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;

    final trimmedMessage = row['message']?.toString().trim();
    final message = trimmedMessage == null || trimmedMessage.isEmpty
        ? null
        : trimmedMessage;
    final eventType = PlantConditionEventTypes.normalize(
      row['event_type']?.toString(),
    );
    final checkedAt = DateTime.tryParse(
      row['created_at']?.toString().trim() ?? '',
    )?.toUtc();

    if (message == null && eventType == null) return null;

    return LatestConditionMemory(
      message: message,
      eventType: eventType,
      checkedAt: checkedAt,
    );
  }
}
