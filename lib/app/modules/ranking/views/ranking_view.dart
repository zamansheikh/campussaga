import 'package:campus_saga/app/data/widgets/app_bar.dart';
import 'package:campus_saga/app/modules/ranking/views/ranking_more_view.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ranking_controller.dart';

class RankingView extends GetView<RankingController> {
  final controller = Get.put(RankingController());
  RankingView({Key? key}) : super(key: key);
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
          title: "Rank of Universities"),
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
        child: Container(
          height: Get.height,
          child: Column(
            children: [
              Expanded(
                // Place Expanded directly inside Column
                child: FirebaseAnimatedList(
                  query: controller.profileRef,
                  itemBuilder:
                      (context, snapshot, Animation<double> animation, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ListTile(
                          onTap: () {
                            controller.snapshot = snapshot;
                            Get.to(() => RankingMoreView());
                          },
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.green,
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                    snapshot
                                        .child("uniProfilePic")
                                        .value
                                        .toString(),
                                  ),
                                  onBackgroundImageError:
                                      (exception, stackTrace) => Text('Error'),
                                ),
                              ),
                              Positioned(
                                  child: (snapshot.child("isVerified").value)
                                          as bool
                                      ? Icon(Icons.verified, color: Colors.blue)
                                      : Icon(Icons.error_outline,
                                          color: Colors.red),
                                  right: 0,
                                  bottom: 0),
                            ],
                          ),
                          title: Text(
                            snapshot.child("uniName").value.toString(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.blue,
                          ),
                          subtitle: Text(
                            snapshot.child("postDescription").value.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Divider(
                          color: Colors.black,
                          thickness: .2,
                        ),
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
