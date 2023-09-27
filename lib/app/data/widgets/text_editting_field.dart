import 'package:flutter/material.dart';

class TextEdittingField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final IconData icon;
  final bool isObscure;
  bool showPass;
  TextEdittingField(
      {super.key,
      this.controller,
      required this.labelText,
      required this.icon,
      this.isObscure = false,
      this.showPass = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        suffixIcon: Visibility(
          visible: isObscure,
          child: IconButton(
              onPressed: () {
                this.showPass = !showPass;
              },
              icon: showPass
                  ? Icon(Icons.visibility_off)
                  : Icon(Icons.visibility)),
        ),
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
      obscureText: !showPass,
    );
  }
}
