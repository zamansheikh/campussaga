import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/cs_icons.dart';
import '../tokens/dimensions.dart';

/// The poster at the top of a prize campaign. With [image] (the banner the
/// team uploaded) it shows the photo under a dark fade; without one it
/// draws its own: a deep teal-to-indigo gradient, confetti and a glowing
/// gift. The title sits at the bottom, the prize in an amber tag, and an
/// optional [tag] ("LIVE · 4d left") at the top.
class CsPrizeBanner extends StatelessWidget {
  const CsPrizeBanner({
    super.key,
    required this.title,
    this.prize,
    this.tag,
    this.image,
    this.height = 168,
    this.topRight,
  });

  final String title;

  /// "Top prize: Smartphone".
  final String? prize;

  /// A small label at the top left.
  final String? tag;
  final ImageProvider? image;
  final double height;

  /// At the top right, across from [tag] ("Powered by" a sponsor).
  final Widget? topRight;

  static const _amber = Color(0xFFFBBF24);
  static const _gradient = [
    Color(0xFF0F766E),
    Color(0xFF134E4A),
    Color(0xFF1E1B4B),
  ];

  @override
  Widget build(BuildContext context) {
    final img = image;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradient,
              ),
            ),
          ),
          if (img == null) ...[
            const CustomPaint(painter: _ConfettiPainter()),
            Positioned(
              right: 18,
              top: topRight == null ? 18 : 44,
              bottom: 18,
              child: const _GlowingGift(),
            ),
          ] else
            Image(
              image: img,
              fit: BoxFit.cover,
              // A broken or slow image leaves the gradient showing.
              errorBuilder: (_, _, _) =>
                  const CustomPaint(painter: _ConfettiPainter()),
            ),
          // Keeps the words readable on any photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.25, 1],
                colors: [Color(0x00000000), Color(0xCC020617)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CsSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag != null || topRight != null)
                  Row(
                    children: [
                      // Both shrink (ellipsis) on a narrow poster or in
                      // long Bangla; the tag keeps more of the room.
                      if (tag != null)
                        Flexible(flex: 3, child: _Tag(text: tag!)),
                      if (topRight != null) ...[
                        const SizedBox(width: CsSpace.sm),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: topRight,
                          ),
                        ),
                      ],
                    ],
                  ),
                const Spacer(),
                Padding(
                  // Leave the gift room when it's drawn.
                  padding: EdgeInsets.only(right: img == null ? 104 : 0),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                if (prize != null) ...[
                  const SizedBox(height: CsSpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _amber,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CsIcons.trophy,
                          size: 15,
                          color: Color(0xFF422006),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            prize!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelMedium?.copyWith(
                              color: const Color(0xFF422006),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0x33FFFFFF),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0x55FFFFFF)),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// A gift in a soft amber glow, with two sparkles.
class _GlowingGift extends StatelessWidget {
  const _GlowingGift();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x99FBBF24), Color(0x22FBBF24), Color(0x00FBBF24)],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        FractionallySizedBox(
          widthFactor: 0.62,
          heightFactor: 0.62,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.12),
              border: Border.all(color: const Color(0x66FBBF24), width: 2),
            ),
            child: const FittedBox(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(CsIcons.gift, color: Color(0xFFFDE68A)),
              ),
            ),
          ),
        ),
        const Align(
          alignment: Alignment(0.8, -0.85),
          child: Icon(CsIcons.sparkle, size: 18, color: Color(0xFFFDE68A)),
        ),
        const Align(
          alignment: Alignment(-0.85, 0.75),
          child: Icon(CsIcons.sparkle, size: 12, color: Color(0xFF99F6E4)),
        ),
      ],
    ),
  );
}

/// Little confetti pieces, the same every time.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  static const _colors = [
    Color(0xFFFBBF24),
    Color(0xFF5EEAD4),
    Color(0xFFF472B6),
    Color(0xFFA5B4FC),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 34; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      paint.color = _colors[i % _colors.length].withValues(
        alpha: 0.35 + r.nextDouble() * 0.45,
      );
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(r.nextDouble() * math.pi);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 1.6 + r.nextDouble() * 1.8, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 3 + r.nextDouble() * 4,
              height: 7 + r.nextDouble() * 5,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
    // Two soft light blooms.
    paint
      ..color = const Color(0x225EEAD4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.1), 60, paint);
    paint.color = const Color(0x22A5B4FC);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.95), 70, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
