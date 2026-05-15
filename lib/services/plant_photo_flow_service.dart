import 'package:image_picker/image_picker.dart';

import 'photo_service.dart';
import 'plant_service.dart';

class PlantPhotoFlowService {
  PlantPhotoFlowService({
    required PhotoService photoService,
    required PlantService plantService,
  }) : _photoService = photoService,
       _plantService = plantService;

  final PhotoService _photoService;
  final PlantService _plantService;

  Future<String> saveRepresentativePhoto({
    required XFile image,
    required String plantId,
  }) async {
    final photoUrl = await _photoService.uploadPlantPhoto(
      image: image,
      plantId: plantId,
    );
    await _plantService.updatePlantPhotoUrlById(plantId, photoUrl);
    await _plantService.insertPlantPhotoHistoryBestEffort(plantId, photoUrl);
    return photoUrl;
  }

  Future<String> saveConditionCheckPhoto({
    required XFile image,
    required String plantId,
  }) async {
    final photoUrl = await _photoService.uploadPlantPhoto(
      image: image,
      plantId: plantId,
    );
    await _plantService.insertPlantPhotoHistoryBestEffort(plantId, photoUrl);

    // Future condition-analysis API should run after this method returns the
    // remote photoUrl. Do not call it from the representative photo flow.
    return photoUrl;
  }
}
