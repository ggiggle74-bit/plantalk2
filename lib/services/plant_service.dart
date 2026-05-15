import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlantService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadPlants() async {
    final data = await _client
        .from('plants')
        .select()
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> addPlant(
    String plantName, {
    String speciesKey = 'unknown',
    String speciesDisplayName = '알 수 없음',
    String? speciesGuess,
  }) async {
    final data = await _client.from('plants').insert({
      'name': plantName,
      'message': '처음 만나서 반가워요 🌱',
      'water_day': 0,
      'species_key': speciesKey,
      'species_display_name': speciesDisplayName,
      'species_guess': speciesGuess,
    }).select().single();

    return Map<String, dynamic>.from(data);
  }

  Future<void> updatePlantNameById(String plantId, String name) async {
    await _client.from('plants').update({'name': name}).eq('id', plantId);
  }

  Future<void> updatePlantWaterDay(String plantName, int waterDay) async {
    await _client
        .from('plants')
        .update({'water_day': waterDay})
        .eq('name', plantName);
  }

  Future<void> updatePlantWaterDayById(String plantId, int waterDay) async {
    await _client
        .from('plants')
        .update({'water_day': waterDay})
        .eq('id', plantId);
  }

  Future<void> updatePlantMessage(String plantName, String message) async {
    await _client
        .from('plants')
        .update({'message': message})
        .eq('name', plantName);
  }

  Future<void> updatePlantMessageById(String plantId, String message) async {
    await _client
        .from('plants')
        .update({'message': message})
        .eq('id', plantId);
  }

  Future<void> updatePlantPhotoUrlById(String plantId, String photoUrl) async {
    await _client
        .from('plants')
        .update({'photo_url': photoUrl})
        .eq('id', plantId);
  }

  Future<void> insertPlantPhotoHistoryBestEffort(
    String plantId,
    String photoUrl,
  ) async {
    try {
      await _client.from('plant_photos').insert({
        'plant_id': plantId,
        'photo_url': photoUrl,
      });
    } catch (error) {
      debugPrint('plant_photos insert failed: $error');
    }
  }

  Future<void> insertPlantMemoryBestEffort({
    required String plantId,
    required String memoryType,
    required String message,
    String? eventType,
    String? photoUrl,
    bool isMock = false,
  }) async {
    try {
      await _client.from('plant_memories').insert({
        'plant_id': plantId,
        'memory_type': memoryType,
        'event_type': eventType,
        'message': message,
        'photo_url': photoUrl,
        'is_mock': isMock,
      });
    } catch (error) {
      debugPrint('plant_memories insert failed: $error');
    }
  }

  Future<Map<String, dynamic>?> fetchLatestPlantMemoryBestEffort({
    required String plantId,
    String memoryType = 'condition_check',
  }) async {
    try {
      final data = await _client
          .from('plant_memories')
          .select(
            'memory_type, event_type, message, photo_url, is_mock, created_at',
          )
          .eq('plant_id', plantId)
          .eq('memory_type', memoryType)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (error) {
      debugPrint('plant_memories fetch failed: $error');
      return null;
    }
  }

  Future<void> updatePlantFriendship(
    String plantName,
    int friendship,
    String mood,
  ) async {
    await _client
        .from('plants')
        .update({'friendship': friendship, 'mood': mood})
        .eq('name', plantName);
  }

  Future<void> updatePlantFriendshipById(
    String plantId,
    int friendship,
    String mood,
  ) async {
    await _client
        .from('plants')
        .update({'friendship': friendship, 'mood': mood})
        .eq('id', plantId);
  }

  Future<void> deletePlant(String plantName) async {
    await _client.from('plants').delete().eq('name', plantName);
  }

  Future<void> deletePlantById(String plantId) async {
    await _client.from('plants').delete().eq('id', plantId);
  }
}
