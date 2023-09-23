import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference postRef = FirebaseDatabase.instance.ref('posts/Issue');

  var postDetailsforMore;
  var postDetails;
  //create a boolean map , name isExpanded
  //when you click on the card , change the value of isExpanded to true
  //when you click on the card again , change the value of isExpanded to false

  var snapshot;
  getData(snapshot) {
    postDetailsforMore = snapshot;
  }

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

  double getUpVotePercentage(String upvotes, String downvotes) {
    double upvote = double.parse(upvotes);
    double downvote = double.parse(downvotes);

    if (upvote == 0 && downvote == 0) {
      return 0.0;
    } else {
      double total = upvote + downvote;
      try {
        double percentage = (upvote / total);
        return percentage;
      } catch (e) {
        print(e);
        return 0.0;
      }
    }
  }

  double adminFeedBackPercentage(String trueVote, String falseVote) {
    double trueVoteDouble = double.parse(trueVote);
    double falseVoteDouble = double.parse(falseVote);
    if (trueVoteDouble == 0 && falseVoteDouble == 0) {
      return 0.0;
    } else {
      double total = trueVoteDouble + falseVoteDouble;
      try {
        double percentage = (trueVoteDouble / total);
        return percentage;
      } catch (e) {
        print(e);
        return 0.0;
      }
    }
  }

  void trueVote(String time) async {
    try {
      await getDataSnapShot(time);
      await postRef
          .child(time)
          .child("trueVotes")
          .set(postDetails.child(time).child("trueVotes").value + 1);
    } catch (e) {
      print(e);
    }
  }

  void falseVote(String time) async {
    try {
      await getDataSnapShot(time);
      await postRef
          .child(time)
          .child("falseVotes")
          .set(postDetails.child(time).child("falseVotes").value + 1);
    } catch (e) {
      print(e);
    }
  }
}
