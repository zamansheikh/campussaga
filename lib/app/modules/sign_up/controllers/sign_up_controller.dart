import 'package:campus_saga/app/constants.dart';
import 'package:campus_saga/app/data/providers/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:searchfield/searchfield.dart';

class SignUpController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  RxBool isLoading = authController.isLoading;

  void registerAUser() async {
    authController.newRegister(
      userName: userNameController.text,
      UvName: universityController.text,
      email: emailController.text,
      password: passwordController.text,
      image: AuthController.instance.pickedImage,
    );
  }

  List<String> university = [
    "DIU",
    "BracU",
    "NSU",
  ];
  List<SearchFieldListItem<dynamic>> suggestions = [];
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
