import 'package:campus_saga/app/data/widgets/post_viewBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ranking_controller.dart';

class RankingMoreView extends GetView<RankingController> {
  final controller = Get.put(RankingController());
  RankingMoreView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF207BFF),
      appBar: PostViewBar(
        title: controller.snapshot!.child("uniName").value.toString(),
        leadingIcon: Icons.arrow_back,
        onPressedLeading: () => Get.back(),
      ),
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
        child: SingleChildScrollView(
          child: Container(
            // height: Get.height,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 73,
                      backgroundColor: Colors.black,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage(
                          controller.snapshot!
                              .child("uniProfilePic")
                              .value
                              .toString(),
                        ),
                        onBackgroundImageError: (exception, stackTrace) =>
                            Text('Error'),
                      ),
                    ),
                    Positioned(
                        child: (controller.snapshot!.child("isVerified").value)
                                as bool
                            ? Icon(Icons.verified, color: Colors.blue)
                            : Icon(Icons.error_outline, color: Colors.red),
                        right: 10,
                        bottom: 10),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                    padding: EdgeInsets.all(15),
                    width: Get.width,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name:",
                          style: TextStyle(
                            fontSize: 18, // Increased font size
                            fontWeight:
                                FontWeight.bold, // Added bold for labels
                          ),
                        ),
                        Text(
                          controller.snapshot!
                              .child("uniName")
                              .value
                              .toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(.7),
                          ),
                        ),
                        SizedBox(height: 8), // Added spacing between items
                        Text(
                          "Description:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          controller.snapshot!
                              .child("postDescription")
                              .value
                              .toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(.7),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Rank:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          controller.snapshot!.child("rank").value.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(.7),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Total Post:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          controller.snapshot!
                              .child("totalPost")
                              .value
                              .toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(.7),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Total Solve Issue:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          controller.snapshot!
                              .child("totalSolve")
                              .value
                              .toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(.7),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Points:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          controller.snapshot!.child("points").value.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(.7),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
