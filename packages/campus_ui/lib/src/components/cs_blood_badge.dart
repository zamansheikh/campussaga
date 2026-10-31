import 'package:flutter/material.dart';

/// A blood group as a red drop-like badge ("A+"), the same red in light
/// and dark (white text passes AA on it).
class CsBloodBadge extends StatelessWidget {
  const CsBloodBadge({super.key, required this.label, this.size = 44});

  final String label;
  final double size;

  /// Blood red.
  static const color = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      // A drop: round with one sharp corner on top.
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(size * 0.12),
        topRight: Radius.circular(size / 2),
        bottomLeft: Radius.circular(size / 2),
        bottomRight: Radius.circular(size / 2),
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: size * 0.2,
          offset: Offset(0, size * 0.06),
        ),
      ],
    ),
    child: FittedBox(
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.36,
            height: 1,
          ),
        ),
      ),
    ),
  );
}
