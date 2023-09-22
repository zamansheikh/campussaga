import 'package:campus_saga/app/data/widgets/post_viewBar.dart';
import 'package:campus_saga/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class HomeReadMoreView extends GetView<HomeController> {
  final HomeController controller = Get.find();
  HomeReadMoreView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF207BFF),
      appBar: PostViewBar(
        title: controller.postDetails.child("postHeading").value.toString(),
        leadingIcon: Icons.arrow_back,
        onPressedLeading: () => Get.back(),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        padding: EdgeInsets.only(top: 15, left: 15, right: 15),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                width: Get.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    controller.postDetails.child("imageUrl").value.toString(),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Image is fully loaded, display it.
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                controller.postDetails.child("postHeading").value.toString(),
                style: TextStyle(
                  fontSize: 24, // Adjust the font size as needed
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Author: Anonymous",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                controller.postDetails
                    .child("postDescription")
                    .value
                    .toString(),
                style: TextStyle(
                  fontSize: 16, // Adjust the font size as needed
                ),
              ),
              // Add any additional widgets or styling as needed
            ],
          ),
        ),
      ),
    );
  }
}
