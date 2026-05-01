class PlantModel {
  final String name;
  final String message;
  final int waterDay;
  final int friendship;
  final String mood;

  const PlantModel({
    required this.name,
    required this.message,
    required this.waterDay,
    required this.friendship,
    required this.mood,
  });

  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      name: map['name'] ?? '',
      message: map['message'] ?? '안녕하세요 🌱',
      waterDay: map['water_day'] ?? 0,
      friendship: map['friendship'] ?? 0,
      mood: map['mood'] ?? '보통',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'message': message,
      'water_day': waterDay,
      'friendship': friendship,
      'mood': mood,
    };
  }
}
