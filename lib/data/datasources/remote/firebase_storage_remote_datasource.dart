import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:firebase_storage/firebase_storage.dart';


// lib/data/datasources/remote/firebase_storage_remote_datasource.dart

class FirebaseStorageRemoteDataSource {
  final FirebaseStorage firebaseStorage;

  FirebaseStorageRemoteDataSource({required this.firebaseStorage});

  Future<String> uploadUserImage(File image, String userId) async {
    final ref = firebaseStorage.ref().child('user_images').child('$userId.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<List<String>> uploadPostImages(String postId, List<File> images) async {
    final urls = <String>[];
    for (final image in images) {
      final ref = firebaseStorage
          .ref()
          .child('post_images')
          .child('$postId-${p.basename(image.path)}.jpg');
      await ref.putFile(image);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<List<String>> uploadPromotionImages(String postId, List<File> images) async {
    final urls = <String>[];
    for (final image in images) {
      final ref = firebaseStorage
          .ref()
          .child('promotion_images')
          .child('$postId-${p.basename(image.path)}.jpg');
      await ref.putFile(image);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<List<String>> uploadVerificationImages(String postId, List<File> images) async {
    final urls = <String>[];
    for (final image in images) {
      final ref = firebaseStorage
          .ref()
          .child('verification_images')
          .child('$postId-${p.basename(image.path)}.jpg');
      await ref.putFile(image);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }
}
