import 'package:campus_saga/app/data/models/new_user_model.dart';
import 'package:campus_saga/app/data/providers/auth/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  AuthController authController = Get.find();
  Rx<userModel> localUserModel = Rx<userModel>(userModel());
  static ProfileController instance = Get.put(ProfileController());
  var profileInfo;

  final FirebaseDatabase database = FirebaseDatabase.instance;
  final DatabaseReference profileRef = FirebaseDatabase.instance
      .ref("profile/${FirebaseAuth.instance.currentUser!.uid}/");

  final count = 0.obs;

  void loadProfileData() async {
    DataSnapshot snapshot = await profileRef.get();
    profileInfo = snapshot.value;
    // print(profileInfo);
  }

  @override
  void onInit() async {
    super.onInit();
    loadProfileData();
    // print("profile/${FirebaseAuth.instance.currentUser!.uid}/");
    // localUserModel.value = await authController.userModelFromSnapshot();
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
}
