import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference postRef = FirebaseDatabase.instance.ref('posts/Issue');
  var postDetails;
  //create a boolean map , name isExpanded
  //when you click on the card , change the value of isExpanded to true
  //when you click on the card again , change the value of isExpanded to false

  RxMap isExpanded = RxMap<int, bool>();

  setExpanded(int index, bool value) => isExpanded[index] = value;

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

  getData(snapshot) {
    postDetails = snapshot;
  }
}
