import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PhotoInputService {
  PhotoInputService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _imagePicker.pickImage(source: source);
    } catch (error) {
      debugPrint('Image picker failed: $error');
      return null;
    }
  }
}
