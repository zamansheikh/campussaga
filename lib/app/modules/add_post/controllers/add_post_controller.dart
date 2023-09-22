import 'dart:io';
import 'package:campus_saga/app/data/providers/add_post_provider.dart';
import 'package:campus_saga/app/modules/profile/controllers/profile_controller.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AddPostController extends GetxController {
  RxString selectedPostType = 'Issue'.obs;
  RxList<String> postTypeList = ['Issue', 'Promotion'].obs;
  final formKey = GlobalKey<FormState>();
  TextEditingController postHeadingController = TextEditingController();
  TextEditingController postDescriptionController = TextEditingController();
  RxInt maxInputLine = 1.obs;
  RxInt maxLine = 4.obs;
  RxInt maxtLineAlloded = 7.obs;
  final count = 0.obs;

  // void maxLineCalculate(var lines) {
  //   maxLine.value =
  //       ((lines.length < 4) ? 4 : lines.length) > maxtLineAlloded.value
  //           ? maxtLineAlloded.value
  //           : lines.length;
  // }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
  String postType() {
    if (selectedPostType.value == "Issue") {
      return "Issue";
    } else {
      return "Promotion";
    }
  }

  final postProviderRef = PostProvider.instance;

  void addPost() async {
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref('posts');
    ProfileController profileController = ProfileController.instance;
    if (formKey.currentState!.validate()) {
      final info = await profileController.profileRef.get();
      print(info.child('profileInfo').child('profilePhoto').value.toString());

      File? image = postProviderRef.pickedImage;
      String userImageUrl =
          info.child('profileInfo').child('profilePhoto').value.toString();
      String postPictureUrl = await postProviderRef.uploadToStorage(image!);
      await databaseRef
          .child(postType())
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .set({
        'userId': info.child('profileInfo').child('uid').value.toString(),
        'postType': selectedPostType.value,
        'postHeading': postHeadingController.text,
        'postDescription': postDescriptionController.text,
        'userProfilePic': userImageUrl,
        'userName': info.child('profileInfo').child('name').value.toString(),
        'imageUrl': postPictureUrl,
        'isSolved': false,
        'upvotes': 1,
        'downvotes': 1,
        'adminFeedback': "",
        'userAgreesToFeedback': "",
      });
      Get.snackbar(
        "Success",
        "Post Added",
      );
    }
  }

  //add university
  void addUniversity() async {
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref('university');
    if (formKey.currentState!.validate()) {
      File? image = postProviderRef.pickedImage;
      String postPictureUrl =
          await postProviderRef.uploadToStorageUniversity(image!);
      String universityId = DateTime.now().millisecondsSinceEpoch.toString();
      await databaseRef.child(universityId).set({
        "isVerified": false,
        'universityId': universityId,
        'postType': selectedPostType.value,
        'uniName': postHeadingController.text,
        'postDescription': postDescriptionController.text,
        'uniProfilePic': postPictureUrl,
        'totalSolve': 0,
        'totalUnsolve ': 0,
        'points': 1,
        'rank': 1,
        'totalPost': 0,
      });
      Get.snackbar(
        "Success",
        "Post Added",
      );
    }
  }
}
