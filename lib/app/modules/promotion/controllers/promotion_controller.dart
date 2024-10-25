import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class PromotionController extends GetxController {
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference postRef = FirebaseDatabase.instance.ref('posts/Promotion/');
  var postDetails;

  RxMap isExpanded = RxMap<int, bool>();
  setExpanded(int index, bool value) => isExpanded[index] = value;
  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
  }


    getDataSnapShot(String time) async {
    try {
      DataSnapshot dataSnapshot = await postRef.get();

      if (dataSnapshot.value != null) {
        //   Map<dynamic, dynamic> data =
        //       dataSnapshot.value as Map<dynamic, dynamic>;
        postDetails = dataSnapshot;
      } else {
        print('No data found.');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }


   void upVote(String time) async {
    try {
      await getDataSnapShot(time);
      await postRef
          .child(time)
          .child("upvotes")
          .set(postDetails.child(time).child("upvotes").value + 1);
    } catch (e) {
      print(e);
    }
  }

  void downVote(String time) async {
    try {
      await getDataSnapShot(time);
      await postRef
          .child(time)
          .child("downvotes")
          .set(postDetails.child(time).child("downvotes").value + 1);
    } catch (e) {
      print(e);
    }
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
