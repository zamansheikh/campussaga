import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class PromotionController extends GetxController {
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference postRef = FirebaseDatabase.instance.ref('posts/Promotion');
  var postDetails;

  RxMap isExpanded = RxMap<int, bool>();
  setExpanded(int index, bool value) => isExpanded[index] = value;
  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
  }

  getData(snapshot) {
    postDetails = snapshot;
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
