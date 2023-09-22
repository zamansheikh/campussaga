import 'package:campus_saga/app/constants.dart';
import 'package:campus_saga/app/data/providers/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  void registerAUser() {
    authController.newRegister(
      userNameController.text,
      emailController.text,
      passwordController.text,
      AuthController.instance.pickedImage,
    );
  }

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
}
