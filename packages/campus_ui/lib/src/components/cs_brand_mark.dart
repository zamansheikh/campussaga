import 'package:flutter/material.dart';

/// The app's mark: ক in a speech bubble on the teal tile, the same artwork
/// as the launcher icon (assets/icon/ at the repo root).
class CsBrandMark extends StatelessWidget {
  const CsBrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.23);
    return Semantics(
      label: 'VarsityKotha',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B5E57).withValues(alpha: 0.26),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(
            'assets/brand/brand_mark.png',
            package: 'campus_ui',
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
