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

  Future<void> addPlant(String plantName) async {
    await _client.from('plants').insert({
      'name': plantName,
      'message': '처음 만나서 반가워요 🌱',
      'water_day': 0,
    });
  }

  Future<void> updatePlantWaterDay(String plantName, int waterDay) async {
    await _client
        .from('plants')
        .update({'water_day': waterDay})
        .eq('name', plantName);
  }

  Future<void> updatePlantMessage(String plantName, String message) async {
    await _client
        .from('plants')
        .update({'message': message})
        .eq('name', plantName);
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

  Future<void> deletePlant(String plantName) async {
    await _client.from('plants').delete().eq('name', plantName);
  }
}
