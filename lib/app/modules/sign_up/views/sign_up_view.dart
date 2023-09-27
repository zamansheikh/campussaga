import 'package:campus_saga/app/data/providers/auth/auth_controller.dart';
import 'package:campus_saga/app/data/widgets/app_bar.dart';
import 'package:campus_saga/app/data/widgets/text_editting_field.dart';
import 'package:campus_saga/app/routes/app_pages.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/sign_up_controller.dart';

class SignUpView extends GetView<SignUpController> {
  final SignUpController controller = Get.put(SignUpController());
  final AuthController authController = Get.put(AuthController());

  SignUpView({Key? key}) : super(key: key);
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
          title: "Sign Up"),
      body: Container(
        height: Get.height,
        width: Get.width,
        padding: EdgeInsets.only(
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
            height: Get.height,
            width: Get.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => authController.picImage(),
                  child: GetBuilder<AuthController>(
                    builder: (controller) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: authController.pickedImage != null
                              ? FileImage(authController.pickedImage!)
                              : null,
                          child: (authController.pickedImage == null)
                              ? Icon(Icons.add_a_photo_rounded)
                              : Image.file(authController.pickedImage!),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                TextEdittingField(
                  controller: controller.userNameController,
                  labelText: "User Name",
                  icon: Icons.email,
                ),
                SizedBox(height: 20),
                TextEdittingField(
                  controller: controller.emailController,
                  labelText: "Email",
                  icon: Icons.email,
                ),
                SizedBox(height: 20),
                TextEdittingField(
                  controller: controller.passwordController,
                  labelText: "Password",
                  icon: Icons.password,
                  isObscure: true,
                ),
                SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Get.offAllNamed(Routes.LOGIN);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Already have any account?",
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        " Log In!",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    controller.registerAUser();
                  },
                  child: Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
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
