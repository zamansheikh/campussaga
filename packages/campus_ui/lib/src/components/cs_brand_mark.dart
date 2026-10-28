import 'package:flutter/material.dart';

import '../tokens/cs_icons.dart';

/// The app's mark: a teal tile with a graduation cap. A placeholder until
/// the final logo; replace this one widget when it arrives.
class CsBrandMark extends StatelessWidget {
  const CsBrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.28),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(CsIcons.academic, color: Colors.white, size: size * 0.56),
    );
  }
}
