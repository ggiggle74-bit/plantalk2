import 'package:image_picker/image_picker.dart';

class PhotoInputService {
  PhotoInputService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<XFile?> pickImage(ImageSource source) {
    return _imagePicker.pickImage(source: source);
  }
}
