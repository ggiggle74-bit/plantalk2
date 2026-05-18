class PlantPhotoHistoryItem {
  const PlantPhotoHistoryItem({
    this.id,
    this.plantId,
    this.photoUrl,
    this.createdAt,
  });

  final String? id;
  final String? plantId;
  final String? photoUrl;
  final DateTime? createdAt;

  factory PlantPhotoHistoryItem.fromRow(Map<String, dynamic> row) {
    final createdAtValue = row['created_at'];

    return PlantPhotoHistoryItem(
      id: row['id']?.toString(),
      plantId: row['plant_id']?.toString(),
      photoUrl: row['photo_url']?.toString(),
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)
          : null,
    );
  }
}
