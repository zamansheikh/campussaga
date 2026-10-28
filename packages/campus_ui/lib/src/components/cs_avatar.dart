import 'package:flutter/material.dart';

/// Round avatar: the person's photo when there is one, else their initials
/// on a colour picked from their name (the same person always gets the same
/// colour). The initials also show while the photo loads or if it fails.
class CsAvatar extends StatelessWidget {
  const CsAvatar({super.key, required this.name, this.size = 48, this.image});

  final String name;
  final double size;
  final ImageProvider? image;

  // Deep tones: white initials stay readable (WCAG AA) on every one.
  static const _palette = [
    [Color(0xFF0F766E), Color(0xFF14B8A6)],
    [Color(0xFF4338CA), Color(0xFF6366F1)],
    [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    [Color(0xFFB45309), Color(0xFFF59E0B)],
    [Color(0xFFBE123C), Color(0xFFFB7185)],
    [Color(0xFF0369A1), Color(0xFF38BDF8)],
  ];

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(context);
    final img = image;
    if (img == null) return initials;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Image(
          image: img,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, sync) =>
              frame == null && !sync ? initials : child,
          errorBuilder: (_, _, _) => initials,
        ),
      ),
    );
  }

  Widget _initials(BuildContext context) {
    final colors =
        _palette[name.codeUnits.fold<int>(0, (a, b) => a + b) %
            _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[0], colors[1]],
        ),
      ),
      child: Text(
        initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
