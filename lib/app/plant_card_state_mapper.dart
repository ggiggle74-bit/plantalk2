String? plantIdOf(Map<String, dynamic> plant) {
  final id = plant['id']?.toString();
  if (id == null || id.isEmpty) return null;
  return id;
}

String? speciesKeyForChat(
  String? plantId,
  Iterable<Map<String, dynamic>> plants,
) {
  final plant = _plantForChat(plantId, plants);
  final key = plant?['speciesKey']?.toString().trim().toLowerCase();
  return key == null || key.isEmpty || key == 'unknown' ? null : key;
}

String? speciesDisplayNameForChat(
  String? plantId,
  Iterable<Map<String, dynamic>> plants,
) {
  if (plantId == null || plantId.isEmpty) return null;

  for (final plant in plants) {
    if (plantIdOf(plant) == plantId) {
      return plant['speciesDisplayName']?.toString();
    }
  }

  return null;
}

String? plantMoodForChat(
  String? plantId,
  Iterable<Map<String, dynamic>> plants,
) {
  final plant = _plantForChat(plantId, plants);
  final mood = plant?['mood']?.toString().trim();
  return mood == null || mood.isEmpty ? null : mood;
}

int? plantFriendshipForChat(
  String? plantId,
  Iterable<Map<String, dynamic>> plants,
) {
  final plant = _plantForChat(plantId, plants);
  final value = plant?['friendship'];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

Map<String, dynamic>? _plantForChat(
  String? plantId,
  Iterable<Map<String, dynamic>> plants,
) {
  if (plantId == null || plantId.isEmpty) {
    return null;
  }

  for (final plant in plants) {
    if (plantIdOf(plant) == plantId) {
      return plant;
    }
  }
  return null;
}

int waterDayOf(Map<String, dynamic> plant) {
  final value = plant['waterDay'] ?? plant['water_day'] ?? 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

void setWaterDay(Map<String, dynamic> plant, int waterDay) {
  plant['waterDay'] = waterDay;
  plant['water_day'] = waterDay;
}

Map<String, dynamic> plantCardStateFromSupabaseRow(Map<String, dynamic> plant) {
  return {
    'id': plant['id'],
    'name': plant['name'],
    'message': plant['message'] ?? '\uc548\ub155\ud558\uc138\uc694 \u{1f331}',
    'waterDay': plant['water_day'] ?? 0,
    'friendship': plant['friendship'] ?? 0,
    'photoPath': plant['photo_url'],
    'speciesKey': plant['species_key'] ?? 'unknown',
    'speciesDisplayName':
        plant['species_display_name'] ?? '\uc54c \uc218 \uc5c6\uc74c',
    'speciesGuess': plant['species_guess'],
    'mood': plant['mood'] ?? '\ubcf4\ud1b5',
  };
}
