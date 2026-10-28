import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
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

  /// A profile photo: picked, then cropped square (with a round guide)
  /// by the student. Null when they cancel either step.
  Future<PickedPhoto?> pickSquare({
    required bool camera,
    required String title,
    required Color color,
  });
}

/// image_picker, resized to at most 1280 px and re-compressed (q80), so
/// uploads are small (docs/CAMPUS_VOICE.md §7). The server cleans the photo
/// again (metadata removed).
class ImagePickerPhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<PickedPhoto?> pick({required bool camera}) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
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

  @override
  Future<PickedPhoto?> pickSquare({
    required bool camera,
    required String title,
    required Color color,
  }) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
      requestFullMetadata: false,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) return null;
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: 800,
      maxHeight: 800,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: color,
          toolbarWidgetColor: Colors.white,
          statusBarLight: false,
          activeControlsWidgetColor: color,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: title,
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
    if (cropped == null) return null;
    return PickedPhoto(bytes: await cropped.readAsBytes());
  }
}
