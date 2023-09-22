import 'package:campus_saga/app/data/providers/auth/auth_controller.dart';
import 'package:campus_saga/app/data/widgets/app_bar.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  final AuthController authController = Get.find();
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF207BFF),
      appBar: CustomAppBar(
          title: "Profile Page",
          leadingIcon: Icons.info,
          onPressedLeading: () {
            _showAlertDialog("Campus Saga by deCodersFamily",
                "Our mission is to provide a platform for students to share their thoughts and ideas.");
          },
          popUpMenu: true,
          popUpMenuWidget: PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    _showAlertDialog(
                        "Feature Missinng", "It will be implemented in future");
                  },
                  child: Text("Edit Profile"),
                ),
              ),
              PopupMenuItem(
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    _showAlertDialog("Campus Saga by deCodersFamily",
                        "Our mission is to provide a platform for students to share their thoughts and ideas.");
                  },
                  child: Text("About Us"),
                ),
              ),
              PopupMenuItem(
                child: TextButton(
                  onPressed: () {
                    authController.logOutUser();
                  },
                  child: Text("Sign Out"),
                ),
              ),
            ],
          )),
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
        child: Column(
          // Use Column here
          children: [
            Expanded(
              // Place Expanded directly inside Column
              child: FirebaseAnimatedList(
                query: controller.profileRef,
                itemBuilder:
                    (context, snapshot, Animation<double> animation, index) {
                  return Column(
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
                                snapshot.child("profilePhoto").value.toString(),
                              ),
                              onBackgroundImageError: (exception, stackTrace) =>
                                  Text('Error'),
                            ),
                          ),
                          Positioned(
                              child:
                                  (snapshot.child("isVerified").value) as bool
                                      ? Icon(Icons.verified, color: Colors.blue)
                                      : Icon(Icons.error_outline,
                                          color: Colors.red),
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
                                snapshot.child("name").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                              SizedBox(
                                  height: 8), // Added spacing between items
                              Text(
                                "Phone Number:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                snapshot.child("phoneNumber").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Gender:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                snapshot.child("gender").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Email:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                snapshot.child("email").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Institute ID No:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                snapshot.child("uid").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Institute Name:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                snapshot.child("university").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Department Name:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                snapshot.child("department").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Verified:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                snapshot.child("isVerified").value.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(.7),
                                ),
                              ),
                            ],
                          )),
                    ],
                  );
                },
              ),
            ),
          ],
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
