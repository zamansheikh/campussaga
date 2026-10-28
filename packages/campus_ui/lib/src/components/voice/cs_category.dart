import 'package:flutter/material.dart';

/// Icon and muted tint of each issue category (wire names from the API).
/// Safety is the only red one. Each icon colour passes 3:1 on light and
/// dark cards (test/color_contrast_test.dart).
abstract final class CsCategoryStyle {
  static IconData icon(String category) => switch (category) {
    'academic' => Icons.school_outlined,
    'hostel' => Icons.bed_outlined,
    'transport' => Icons.directions_bus_outlined,
    'facilities' => Icons.handyman_outlined,
    'safety' => Icons.health_and_safety_outlined,
    'administration' => Icons.account_balance_outlined,
    'food' => Icons.restaurant_outlined,
    'it' => Icons.wifi,
    _ => Icons.forum_outlined,
  };

  static Color color(String category) => switch (category) {
    'academic' => const Color(0xFF3A7BEA),
    'hostel' => const Color(0xFF8B5CF6),
    'transport' => const Color(0xFF0891B2),
    'facilities' => const Color(0xFFA8761A),
    'safety' => const Color(0xFFDC2626),
    'administration' => const Color(0xFF6D6AF0),
    'food' => const Color(0xFFEA580C),
    'it' => const Color(0xFF0D9488),
    _ => const Color(0xFF64748B),
  };
}

/// Category icon on a soft tile.
class CsCategoryIcon extends StatelessWidget {
  const CsCategoryIcon({super.key, required this.category, this.size = 40});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = CsCategoryStyle.color(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        CsCategoryStyle.icon(category),
        color: color,
        size: size * 0.55,
      ),
    );
  }
}
