import 'package:campus_saga/app/constants.dart';
import 'package:campus_saga/app/data/widgets/app_bar.dart';
import 'package:campus_saga/app/data/widgets/text_editting_field.dart';
import 'package:campus_saga/app/routes/app_pages.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  final LoginController controller = Get.put(LoginController());
  LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          title: "Log In"),
      body: Container(
        height: Get.height,
        width: Get.width,
        // alignment: Alignment.center,
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
        child: Center(
          child: Column(
            children: [
              Spacer(),
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
                  Get.offAllNamed(Routes.SIGN_UP);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Don't have any account? ",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      "Register!",
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
                  authController.logInUser(controller.emailController.text,
                      controller.passwordController.text);
                },
                child: Text(
                  "Log In",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Spacer(),
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
