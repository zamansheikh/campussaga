import 'dart:io';
import 'package:campus_saga/app/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PostProvider extends GetxController {
  static PostProvider instance = Get.put(PostProvider());

  @override
  void onReady() async {
    super.onReady();
  }

  // late Rx<File?> _pickedImage;
  late Rx<File?> _pickedImage = Rx<File?>(null);

  //picImageFunc
  void picImage() async {
    final pickImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickImage != null) {
      Get.snackbar("Success", "Image Picked");
    }
    _pickedImage = Rx<File?>(File(pickImage!.path));
    update();
  }

  //getters

  File? get pickedImage => _pickedImage.value;
  set pickedImage(File? value) => _pickedImage.value = value!;

  //uploading image to firebase storage
  Future<String> _uploadToStorage(File image) async {
    Reference ref = await firebaseStorage
        .ref()
        .child('postImages')
        .child(firebaseAuth.currentUser!.uid);

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  get uploadToStorage => _uploadToStorage;

  Future<String> _uploadPostToStorage(File image) async {
    Reference ref = await firebaseStorage
        .ref()
        .child('postImages')
        .child(DateTime.now().millisecondsSinceEpoch.toString());

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  get uploadPostToStorage => _uploadPostToStorage;

  Future<String> _uploadToStorageUniversity(File image) async {
    Reference ref = await firebaseStorage
        .ref()
        .child('univerSityImages')
        .child(DateTime.now().microsecondsSinceEpoch.toString());

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  get uploadToStorageUniversity => _uploadToStorageUniversity;
}
