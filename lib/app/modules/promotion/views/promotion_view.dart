import 'package:campus_saga/app/data/widgets/app_bar.dart';
import 'package:campus_saga/app/modules/profile/controllers/profile_controller.dart';
import 'package:campus_saga/app/modules/promotion/views/promotion_read_more_view.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../controllers/promotion_controller.dart';

class PromotionView extends GetView<PromotionController> {
  final controller = Get.put(PromotionController());
  final profileController = Get.put(ProfileController());
  PromotionView({Key? key}) : super(key: key);
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
          title: "Promotions"),
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
          InkWell(
            onTap: () async {
              //gotothe next screen!
              await controller.getData(snapshot);

              Get.to(() => PromotionReadMoreView());
            },
            child: Row(
              children: [
                CircleAvatar(
                    radius: 20,
                    backgroundImage: Image.network(
                            snapshot.child("userProfilePic").value.toString())
                        .image),
                SizedBox(width: 10),
                Text(
                  snapshot.child("userName").value.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              //gotothe next screen!
              await controller.getData(snapshot);

              Get.to(() => PromotionReadMoreView());
            },
            child: Container(
              padding: EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.child("postHeading").value.toString(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          snapshot.child("postDescription").value.toString(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            snapshot.child("imageUrl").value.toString(),
                            height: 200,
                            width: Get.width,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  LinearPercentIndicator(
                    percent: snapshot.child("upvotes").value /
                        (snapshot.child("upvotes").value +
                            snapshot.child("downvotes").value),
                    progressColor: Color(0xFF207BFF),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          controller
                              .upVote(snapshot.child("time").value.toString());
                          //Change Upvote
                        },
                        icon: Icon(Icons.thumb_up),
                      ),
                      Text(
                        snapshot.child("upvotes").value.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          controller.downVote(
                              snapshot.child("time").value.toString());
                          //Change Downvote
                        },
                        icon: Icon(Icons.thumb_down),
                      ),
                      Text(
                        snapshot.child("downvotes").value.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Center(
                        child: IconButton(
                          onPressed: () async {
                            //gotothe next screen!
                            await controller.getData(snapshot);

                            Get.to(() => PromotionReadMoreView());
                          },
                          icon: Icon(Icons.read_more),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
