// lib/presentation/widgets/text_editing_field.dart

import 'package:flutter/material.dart';

class TextEditingField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool isObscure;

  const TextEditingField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.isObscure = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      obscureText: isObscure,
    );
  }
}
