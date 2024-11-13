// lib/presentation/widgets/text_editing_field.dart

import 'package:flutter/material.dart';

class TextEditingField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool isObscure;
  final String? Function(String?)? validator;
  final Color? backgroundColor; // Background of the entire field container
  final Color? hintTextColor; // Color for hint and label text
  final Color? fillColor; // Background color inside the field

  const TextEditingField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.isObscure = false,
    this.validator,
    this.backgroundColor,
    this.hintTextColor,
    this.fillColor,
  }) : super(key: key);

  @override
  _TextEditingFieldState createState() => _TextEditingFieldState();
}

class _TextEditingFieldState extends State<TextEditingField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ??
          Colors.transparent, // Apply background color if provided
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: widget.hintTextColor ??
                Colors.grey, // Apply hint text color if provided
          ),
          prefixIcon: Icon(
            widget.icon,
            color: widget.hintTextColor ??
                Colors.grey, // Apply icon color to match hint color
          ),
          suffixIcon: widget.isObscure
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                    color: widget.hintTextColor ??
                        Colors.grey, // Icon color for visibility toggle
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: widget.fillColor ??
              Colors.white, // Fill inside of the field if color provided
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide.none, // Hide border to match filled background
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: widget.hintTextColor ?? Colors.grey),
          ),
        ),
        obscureText: _isObscure,
        validator: widget.validator,
      ),
    );
  }
}
