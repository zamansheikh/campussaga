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
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    await controller.getData(snapshot);
                    Get.to(() => HomeReadMoreView());
                  },
                  child: Text(
                    snapshot.child("postHeading").value.toString(),
                    style: TextStyle(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          await controller.getData(snapshot);
                          Get.to(() => HomeReadMoreView());
                        },
                        child: Text(
                          snapshot.child("postDescription").value.toString(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await controller.getData(snapshot);
                        Get.to(() => HomeReadMoreView());
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          snapshot.child("imageUrl").value.toString(),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            //Change Upvote
                          },
                          icon: Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          onPressed: () {
                            //Change Downvote
                          },
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                LinearPercentIndicator(
                  percent: .9, //!Calulate the percentage
                  progressColor: Color(0xFF207BFF),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              controller.isExpanded[index] = !controller.isExpanded[index];
            },
            icon: controller.isExpanded[index]
                ? Icon(Icons.keyboard_arrow_down)
                : Icon(Icons.keyboard_arrow_up),
          ),

          //add a condition here, if controller.isExpanded == true , only then show the column,
          if (controller.isExpanded[index])
            controller.isExpanded[index]
                ? Column(
                    children: [
                      Divider(thickness: 2),
                      Text("Solved"),
                      SizedBox(height: 5),
                      LinearPercentIndicator(
                        percent: .9, //controller.votingParcentis(index),
                        progressColor: Colors.green,
                        backgroundColor: Colors.red,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Implement 'Yes' button logic.
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
                              // Implement 'No' button logic.
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
                      Text("Authority's Comment"),
                      SizedBox(height: 5),
                      Text("Admins Feed Back"),
                      controller.isExpanded[index]
                          ? IconButton(
                              onPressed: () {
                                controller.isExpanded[index] =
                                    !controller.isExpanded[index];
                              },
                              icon: Icon(Icons.keyboard_arrow_up),
                            )
                          : SizedBox(),
                    ],
                  )
                : SizedBox()
          else
            SizedBox(
              child: controller.isExpanded[index]
                  ? IconButton(
                      onPressed: () {
                        controller.isExpanded[index] =
                            !controller.isExpanded[index];
                      },
                      icon: Icon(Icons.keyboard_arrow_up),
                    )
                  : SizedBox(),
            )
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
