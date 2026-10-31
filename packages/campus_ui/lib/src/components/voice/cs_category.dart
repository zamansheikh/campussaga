import 'package:flutter/material.dart';

import '../../tokens/cs_icons.dart';

/// Icon and muted tint of each category (wire names from the API).
/// Safety is the only red one. Each icon colour passes 3:1 on light and
/// dark cards (test/color_contrast_test.dart).
abstract final class CsCategoryStyle {
  static IconData icon(String category) => switch (category) {
    'academic' => CsIcons.academic,
    'hostel' => CsIcons.hostel,
    'transport' => CsIcons.bus,
    'facilities' => CsIcons.maintenance,
    'safety' => CsIcons.safety,
    'administration' => CsIcons.university,
    'food' => CsIcons.food,
    'it' => CsIcons.wifi,
    'general' => CsIcons.general,
    'event' => CsIcons.event,
    'lost_found' => CsIcons.lostFound,
    'buy_sell' => CsIcons.buySell,
    'fun' => CsIcons.fun,
    _ => CsIcons.campus,
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
    'general' => const Color(0xFF3B82F6),
    'event' => const Color(0xFFDB2777),
    'lost_found' => const Color(0xFF059669),
    'buy_sell' => const Color(0xFFB45309),
    'fun' => const Color(0xFFC026D3),
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
