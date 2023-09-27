import 'dart:io';
import 'dart:math';

import 'package:campus_saga/app/constants.dart';
import 'package:campus_saga/app/routes/app_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference databaseRef = FirebaseDatabase.instance.ref('profile');
  String? userId;
  RxBool isLoading = false.obs;

  // Rx Variables
  late Rx<User?> _firebaseUser;

  get firebaseUser => _firebaseUser.value;

  // Future<dynamic> _userModelFromSnapshot() async {
  //   var userId = await firebaseAuth.currentUser!.uid;
  //   DocumentSnapshot userDoc =
  //       await fireStore.collection('users').doc(userId).get();
  //   var userInfo = await userDoc.data() as Map<String, dynamic>;
  //   return await userModel.fromJson(userInfo);
  // }

  // Future<dynamic> userModelFromSnapshot() async {
  //   return await _userModelFromSnapshot();
  // }

  @override
  void onReady() async {
    super.onReady();
    _firebaseUser = Rx<User?>(firebaseAuth.currentUser);
    _firebaseUser.bindStream(firebaseAuth.authStateChanges());
    ever(_firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? _firebaseUser) {
    if (_firebaseUser != null) {
      Get.offAllNamed(Routes.BOTTOM_BAR);
    } else {
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  // late Rx<File?> _pickedImage;
  late Rx<File?> _pickedImage = Rx<File?>(null);

  //picImageFunc
  void picImage() async {
    final pickImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickImage != null) {
      Get.snackbar("Success", "Image Picked", backgroundColor: Colors.white);
      _pickedImage = Rx<File?>(File(pickImage.path));
      update();
    }
  }

  //getters

  File? get pickedImage => _pickedImage.value;

  //uploading image to firebase storage
  Future<String> _uploadToStorage(File image) async {
    Reference ref = await firebaseStorage
        .ref()
        .child('userProfilePics')
        .child(firebaseAuth.currentUser!.uid);

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // Registering User

  // void registerUser(
  //     String userName, String email, String password, File? image) async {
  //   try {
  //     if (userName.isNotEmpty &&
  //         email.isNotEmpty &&
  //         password.isNotEmpty &&
  //         image != null) {
  //       //Registering User  Here
  //       UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
  //           email: email, password: password);
  //       String downloadUrl = await _uploadToStorage(image);
  //       model.User user = model.User(
  //         name: userName,
  //         phoneNumber: "",
  //         email: email,
  //         password: password,
  //         profilePhoto: downloadUrl,
  //         uid: cred.user!.uid,
  //         gender: "",
  //         university: "",
  //         department: "",
  //         isVerified: false,
  //       );
  //       await fireStore
  //           .collection('users')
  //           .doc(cred.user!.uid)
  //           .set(user.toJson());
  //     } else {
  //       Get.snackbar("Error Creating Accouont", "Plase Enter All Info");
  //     }
  //   } catch (e) {
  //     Get.snackbar("RegisterError!", e.toString());
  //   }
  // }

  void newRegister(
      {required String userName,
      required String UvName,
      required String email,
      required String password,
      required File? image}) async {
    try {
      isLoading.value = true; // Start Loading
      if (userName.isNotEmpty &&
          UvName.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          image != null) {
        UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password);

        userId = cred.user?.uid; // Update userId
        print(userId);
        String downloadUrl = await _uploadToStorage(image);

        await databaseRef.child(userId.toString()).child("profileInfo").set({
          'name': userName,
          'phoneNumber': "",
          'email': email,
          'password': password,
          'profilePhoto': downloadUrl,
          'uid': userId, // Use userId here
          'gender': "Not Specified",
          'university': UvName,
          'department': "N/A",
          'isVerified': false,
        });
        Get.snackbar("Success", "Now you can login",
            backgroundColor: Colors.white);
        isLoading.value = false;
      } else {
        Get.snackbar("Error Creating Account", "Please Enter All Info",
            backgroundColor: Colors.white);
        isLoading.value = false;
      }
    } catch (e) {
      Get.snackbar("Register Error!", e.toString(),
          backgroundColor: Colors.white);
      isLoading.value = false;
    }
  }

  void logInUser(String email, String password) async {
    try {
      isLoading.value = true;
      if (email.isNotEmpty && password.isNotEmpty) {
        await firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password);
        print("LogInSuccess");
        isLoading.value = false;
      } else {
        Get.snackbar("Error Logging In", e.toString(),
            backgroundColor: Colors.white);
        isLoading.value = false;
      }
    } catch (e) {
      Get.snackbar("Error Logging In", e.toString(),
          backgroundColor: Colors.white);
      isLoading.value = false;
    }
  }

  void logOutUser() async {
    try {
      await firebaseAuth.signOut();
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar("Error Logging Out", e.toString(),
          backgroundColor: Colors.white);
    }
  }
}
