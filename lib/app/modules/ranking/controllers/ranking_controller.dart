import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class RankingController extends GetxController {
  final FirebaseDatabase database = FirebaseDatabase.instance;
  final DatabaseReference profileRef =
      FirebaseDatabase.instance.ref("university");
  DataSnapshot? snapshot;

  final count = 0.obs;
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
}
