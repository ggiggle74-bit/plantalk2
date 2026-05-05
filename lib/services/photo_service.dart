import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadPlantPhoto({
    required XFile image,
    required String plantId,
  }) async {
    final bytes = await image.readAsBytes();
    final objectPath =
        'plants/$plantId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('plant-photos').uploadBinary(objectPath, bytes);

    return _client.storage.from('plant-photos').getPublicUrl(objectPath);
  }
}
