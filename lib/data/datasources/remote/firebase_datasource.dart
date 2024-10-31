// lib/data/datasources/remote/firebase_datasource.dart

import 'dart:io';

import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';

class FirebaseDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  FirebaseDataSource(
      {required this.firebaseAuth,
      required this.firestore,
      required this.firebaseStorage});

  Future<UserModel?> getUserProfile(String userId) async {
    final userDoc = await firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return UserModel.fromJson(userDoc.data()!);
    }
    return null;
  }

  Future<String> signUpUser(UserParams user) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: user.email,
      password: user.password,
    );

    return userCredential.user!.uid;
  }

  Future<void> createUser(UserModel user) async {
    await firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> createPost(PostModel post) async {
    await firestore.collection('posts').add(post.toJson());
  }

  Future<List<PostModel>> fetchPosts(String universityId) async {
    final querySnapshot = await firestore
        .collection('posts')
        .where('universityId', isEqualTo: universityId)
        .get();

    return querySnapshot.docs
        .map((doc) => PostModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> updatePostStatus(String postId, bool isResolved) async {
    await firestore.collection('posts').doc(postId).update({
      'isResolved': isResolved,
    });
  }

  Future<String> uploadUserImage(File image, String userId) async {
    try {
      final ref =
          firebaseStorage.ref().child('user_images').child('$userId.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed');
    }
  }

  //logOut
  Future<void> signOutUser() async {
    await firebaseAuth.signOut();
  }
}
