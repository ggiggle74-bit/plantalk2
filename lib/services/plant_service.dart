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

  Future<Map<String, dynamic>> addPlant(String plantName) async {
    final data = await _client.from('plants').insert({
      'name': plantName,
      'message': '처음 만나서 반가워요 🌱',
      'water_day': 0,
    }).select().single();

    return Map<String, dynamic>.from(data);
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
