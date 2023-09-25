import 'package:campus_saga/app/data/widgets/app_bar.dart';
import 'package:campus_saga/app/modules/home/views/home_read_more_view.dart';
import 'package:campus_saga/app/modules/profile/controllers/profile_controller.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  final controller = Get.put(HomeController());
  final profileController = Get.put(ProfileController());
  HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF207BFF),
      appBar: CustomAppBar(
          actionIcon: Icons.dark_mode,
          onPressedAction: () {
            Get.changeTheme(
              Get.isDarkMode ? ThemeData.light() : ThemeData.dark(),
            );
          },
          leadingIcon: Icons.info,
          onPressedLeading: () {
            _showAlertDialog("Campus Saga by deCodersFamily",
                "Our mission is to provide a platform for students to share their thoughts and ideas.");
          },
          title: "Campus Saga"),
      body: Container(
        height: Get.height,
        width: Get.width,
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: Get.height,
          width: Get.width,
          child: Column(
            children: [
              Expanded(
                child: FirebaseAnimatedList(
                  query: controller.postRef,
                  itemBuilder: (context, snapshot, animation, index) {
                    return Column(
                      children: [
                        _cardContainer(index, snapshot),
                        SizedBox(height: 15),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardContainer(int index, snapshot) {
    controller.isExpanded[index] = controller.isExpanded[index] ?? false;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                  radius: 20,
                  backgroundImage: Image.network(
                          snapshot.child("userProfilePic").value.toString())
                      .image),
              SizedBox(width: 10),
              Text('Anonymous'),
              Spacer(),
              Checkbox(
                value: snapshot.child("isSolved").value as bool,
                onChanged: (bool? newValue) {
                  // Implement logic for handling checkbox state change.
                },
                fillColor: snapshot.child("isSolved").value as bool
                    ? MaterialStateProperty.all(Colors.green)
                    : MaterialStateProperty.all(Colors.red),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(5),
            child: InkWell(
              onTap: () async {
                await controller.getData(snapshot);
                Get.to(() => HomeReadMoreView());
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.child("postHeading").value.toString(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          snapshot.child("postDescription").value.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          snapshot.child("imageUrl").value.toString(),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () {
                              print(snapshot.child("time").value.toString());
                              controller.upVote(
                                  snapshot.child("time").value.toString());
                            },
                            icon: Icon(Icons.arrow_upward, color: Colors.green),
                          ),
                          IconButton(
                            onPressed: () {
                              controller.downVote(
                                  snapshot.child("time").value.toString());
                              // controller.downVote();
                            },
                            icon: Icon(Icons.arrow_downward, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  LinearPercentIndicator(
                    percent: controller.getUpVotePercentage(
                        snapshot.child("upvotes").value.toString(),
                        snapshot.child("downvotes").value.toString()),
                    progressColor: Color(0xFF207BFF),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text(
                          "Upvotes: " +
                              snapshot.child("upvotes").value.toString() +
                              " ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Text(
                          "Downvotes: " +
                              snapshot.child("downvotes").value.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => Column(
              children: [
                Visibility(
                  visible: controller.isExpanded[index],
                  child: Column(
                    children: [
                      Divider(thickness: 2),
                      Text("Are you agree with the Admins Feedback?",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      LinearPercentIndicator(
                        percent: controller.adminFeedBackPercentage(
                          snapshot.child("trueVotes").value.toString(),
                          snapshot.child("falseVotes").value.toString(),
                        ),
                        progressColor: Colors.green,
                        backgroundColor: Colors.red,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              controller.trueVote(
                                  snapshot.child("time").value.toString());
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.black,
                            ),
                            child: Text('Yes'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.falseVote(
                                  snapshot.child("time").value.toString());
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.black,
                            ),
                            child: Text('No'),
                          ),
                        ],
                      ),
                      Divider(thickness: 2),
                      Text("Admins Feed Back",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Divider(thickness: 2),
                      Text(snapshot.child("adminFeedback").value.toString()),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    snapshot.child("isSolved").value as bool
                        ? controller.isExpanded[index] =
                            !controller.isExpanded[index]
                        : false;
                  },
                  child: controller.isExpanded[index]
                      ? Icon(Icons.keyboard_arrow_up)
                      : Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDialog(String title, String content) {
    Get.defaultDialog(
      title: title,
      middleText: content,
      textConfirm: "OK",
      onConfirm: () {
        Get.back(); // Close the dialog
      },
    );
  }
}
