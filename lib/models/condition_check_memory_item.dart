import '../services/plant_condition_analysis_service.dart';

class ConditionCheckMemoryItem {
  const ConditionCheckMemoryItem({
    this.plantId,
    this.message,
    this.eventType,
    this.photoUrl,
    this.isMock = false,
    this.createdAt,
  });

  final String? plantId;
  final String? message;
  final String? eventType;
  final String? photoUrl;
  final bool isMock;
  final DateTime? createdAt;

  factory ConditionCheckMemoryItem.fromRow(Map<String, dynamic> row) {
    final createdAtValue = row['created_at'];

    return ConditionCheckMemoryItem(
      plantId: row['plant_id']?.toString(),
      message: _trimmedOrNull(row['message']),
      eventType: PlantConditionEventTypes.normalize(
        row['event_type']?.toString(),
      ),
      photoUrl: _trimmedOrNull(row['photo_url']),
      isMock: row['is_mock'] == true,
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)
          : null,
    );
  }

  static String? _trimmedOrNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
