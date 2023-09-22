import 'package:flutter/material.dart';

class TextEdittingField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final IconData icon;
  final bool isObscure;
  const TextEdittingField(
      {super.key,
      this.controller,
      required this.labelText,
      required this.icon,
      this.isObscure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        labelStyle: const TextStyle(fontSize: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          // borderSide: const BorderSide(
          //   color: Color(borderColor),
          // ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          // borderSide: const BorderSide(
          //   color: borderColor,
          // ),
        ),
      ),
      obscureText: isObscure,
    );
  }
}
