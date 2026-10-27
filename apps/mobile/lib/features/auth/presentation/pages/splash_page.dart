import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

/// Shown for a moment while the saved session is restored.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CsBrandMark(size: 88)));
  }
}
