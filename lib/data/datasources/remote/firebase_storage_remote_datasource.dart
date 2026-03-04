// lib/data/datasources/remote/firebase_storage_remote_datasource.dart
// NOTE: Despite the class name (kept for compatibility), this now uploads
//       to Cloudinary instead of Firebase Storage.

import 'dart:io';
import 'package:campussaga/core/services/cloudinary_service.dart';

class FirebaseStorageRemoteDataSource {
  final CloudinaryService cloudinaryService;

  FirebaseStorageRemoteDataSource({required this.cloudinaryService});

  /// Upload a user profile photo and return the Cloudinary secure URL.
  Future<String> uploadUserImage(File image, String userId) async {
    return cloudinaryService.uploadImage(
      file: image,
      folder: 'campus_saga/user_images',
      publicId: 'user_$userId',
    );
  }

  /// Upload images for an issue/problem post.
  Future<List<String>> uploadPostImages(
    String postId,
    List<File> images,
  ) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final url = await cloudinaryService.uploadImage(
        file: images[i],
        folder: 'campus_saga/post_images',
        publicId: 'post_${postId}_$i',
      );
      urls.add(url);
    }
    return urls;
  }

  /// Upload images for a promotion post.
  Future<List<String>> uploadPromotionImages(
    String postId,
    List<File> images,
  ) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final url = await cloudinaryService.uploadImage(
        file: images[i],
        folder: 'campus_saga/promotion_images',
        publicId: 'promo_${postId}_$i',
      );
      urls.add(url);
    }
    return urls;
  }

  /// Upload selfie + ID card photos for verification.
  Future<List<String>> uploadVerificationImages(
    String userId,
    List<File> images,
  ) async {
    final urls = <String>[];
    final labels = ['selfie', 'id_card'];
    for (int i = 0; i < images.length; i++) {
      final url = await cloudinaryService.uploadImage(
        file: images[i],
        folder: 'campus_saga/verification',
        publicId: 'verify_${userId}_${labels.length > i ? labels[i] : i}',
      );
      urls.add(url);
    }
    return urls;
  }
}
