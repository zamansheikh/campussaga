import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// A photo chosen for an issue, already made smaller on the phone.
class PickedPhoto {
  const PickedPhoto({
    required this.bytes,
    this.filename = 'photo.jpg',
    this.contentType = 'image/jpeg',
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

/// Picks a photo from the gallery or camera.
abstract interface class PhotoPicker {
  /// Null when the student cancels.
  Future<PickedPhoto?> pick({required bool camera});
}

/// image_picker, resized to at most 1600 px and re-compressed (q85), so
/// uploads are small (docs/CAMPUS_VOICE.md §7). The server cleans the photo
/// again (metadata removed).
class ImagePickerPhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<PickedPhoto?> pick({required bool camera}) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final name = file.name.toLowerCase();
    final type = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    return PickedPhoto(
      bytes: await file.readAsBytes(),
      filename: type == 'image/jpeg'
          ? 'photo.jpg'
          : 'photo.${type.split('/').last}',
      contentType: type,
    );
  }
}
