import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/cs_icons.dart';
import '../tokens/dimensions.dart';

/// The colour of a badge tier: bronze, silver and gold, and the metal
/// shading of the rim and ribbon. The same in light and dark.
abstract final class CsTierColors {
  static const bronze = Color(0xFFB4672A);
  static const silver = Color(0xFF8A94A6);
  static const gold = Color(0xFFD4A017);

  /// 1 bronze, 2 silver, 3 gold; null for badges without tiers.
  static Color? of(int tier) => switch (tier) {
    1 => bronze,
    2 => silver,
    3 => gold,
    _ => null,
  };

  /// Light to dark, for a metal look (top to bottom).
  static List<Color>? metal(int tier) => switch (tier) {
    1 => const [Color(0xFFF6C99A), bronze, Color(0xFF7A3E12)],
    2 => const [Color(0xFFF8FAFC), Color(0xFFB8C1CF), Color(0xFF5F6B7D)],
    3 => const [Color(0xFFFFF1B8), gold, Color(0xFF8A6408)],
    _ => null,
  };
}

/// Each badge's own colours (light, dark) and shape. Roles are cut like a
/// gem (a hexagon); things you do are a rosette.
abstract final class CsBadgeColors {
  static (Color, Color) of(String key) => switch (key) {
    'verified' => (const Color(0xFF2DD4BF), const Color(0xFF0F766E)),
    'founding' => (const Color(0xFFA78BFA), const Color(0xFF5B21B6)),
    'cr' => (const Color(0xFFFBBF24), const Color(0xFFB45309)),
    'campus_admin' => (const Color(0xFF818CF8), const Color(0xFF3730A3)),
    'bus_rep' => (const Color(0xFF38BDF8), const Color(0xFF0369A1)),
    'official' => (const Color(0xFF94A3B8), const Color(0xFF334155)),
    'section_builder' => (const Color(0xFF34D399), const Color(0xFF047857)),
    'blood_donor' => (const Color(0xFFF87171), const Color(0xFF991B1B)),
    'life_saver' => (const Color(0xFFFB7185), const Color(0xFF9F1239)),
    'bus_buddy' => (const Color(0xFFFDBA74), const Color(0xFFC2410C)),
    'connector' => (const Color(0xFFE879F9), const Color(0xFF86198F)),
    'bug_hunter' => (const Color(0xFFA3E635), const Color(0xFF3F6212)),
    'helper' => (const Color(0xFF67E8F9), const Color(0xFF0E7490)),
    'campus_voice' => (const Color(0xFF60A5FA), const Color(0xFF1E40AF)),
    'champion_section' => (const Color(0xFFFCD34D), const Color(0xFFB45309)),
    'race_finisher' => (const Color(0xFF4ADE80), const Color(0xFF15803D)),
    'ambassador' => (const Color(0xFFF472B6), const Color(0xFF9D174D)),
    _ => (const Color(0xFF2DD4BF), const Color(0xFF0F766E)),
  };

  /// Roles are hexagons; activity badges (and unknown ones) rosettes.
  static bool isRole(String key) => const {
    'verified',
    'founding',
    'cr',
    'campus_admin',
    'bus_rep',
    'official',
    'section_builder',
    'ambassador',
  }.contains(key);
}

/// How a badge is painted: its fill, its rim, and the tier ribbon.
@immutable
class CsBadgeLook {
  const CsBadgeLook({
    required this.fill,
    required this.rim,
    required this.hexagon,
    required this.emblem,
    this.ribbon,
    this.stars = 0,
    this.shine = true,
  });

  /// Light to dark.
  final List<Color> fill;

  /// The rim, top to bottom (one colour: flat).
  final List<Color> rim;
  final bool hexagon;
  final Color emblem;

  /// The tier ribbon's metal, with [stars] on it (null: no ribbon).
  final List<Color>? ribbon;
  final int stars;
  final bool shine;
}

/// A badge as a medal in its own colour, with a white emblem: roles are
/// gem-cut hexagons, things you do are rosettes. A tier gets a bronze,
/// silver or gold rim and, on larger ones, a ribbon with 1 to 3 stars.
/// [locked] is a grey outline of the same shape. Small ones (under 30)
/// sit next to names.
class CsBadgeIcon extends StatelessWidget {
  const CsBadgeIcon({
    super.key,
    required this.badgeKey,
    this.tier = 0,
    this.size = 44,
    this.locked = false,
    this.semanticLabel,
  });

  final String badgeKey;
  final int tier;
  final double size;
  final bool locked;
  final String? semanticLabel;

  /// The look of [key] at [tier]; [locked] is grey.
  static CsBadgeLook look(
    BuildContext context,
    String key, {
    int tier = 0,
    bool locked = false,
  }) {
    final cs = context.cs;
    final hexagon = CsBadgeColors.isRole(key);
    if (locked) {
      return CsBadgeLook(
        fill: [cs.surfaceVariant, cs.surfaceVariant],
        rim: [cs.border],
        hexagon: hexagon,
        emblem: cs.textSecondary,
        shine: false,
      );
    }
    final (light, dark) = CsBadgeColors.of(key);
    final metal = CsTierColors.metal(tier);
    return CsBadgeLook(
      fill: [light, dark],
      rim: metal ?? [Color.lerp(light, Colors.white, 0.55)!, light],
      hexagon: hexagon,
      emblem: Colors.white,
      ribbon: metal,
      stars: metal == null ? 0 : tier.clamp(1, 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = CsBadgeIcon.look(
      context,
      badgeKey,
      tier: tier,
      locked: locked,
    );
    final big = size >= 40;
    // Room at the bottom for the ribbon on big badges, always, so badges
    // with and without tiers line up.
    final centerY = big ? 0.45 : 0.5;
    final radius = big ? 0.43 : 0.5;
    final icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedalPainter(
          look: look,
          centerY: centerY,
          radius: radius,
          ribbon: big,
        ),
        child: Align(
          alignment: Alignment(0, centerY * 2 - 1),
          child: Icon(
            CsIcons.badgeFill(badgeKey),
            size: size * radius * (look.hexagon ? 0.92 : 0.86),
            color: look.emblem,
            shadows: look.shine && size >= 30
                ? [Shadow(color: look.fill.last, blurRadius: size * 0.08)]
                : null,
          ),
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: icon);
  }
}

/// An empty badge-sized hexagon with [child] in it ("+3", a lock): for the
/// "more" and "to earn" places in a row of badges.
class CsBadgeSlot extends StatelessWidget {
  const CsBadgeSlot({super.key, required this.child, this.size = 44});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final big = size >= 40;
    final centerY = big ? 0.45 : 0.5;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedalPainter(
          look: CsBadgeLook(
            fill: [cs.surfaceVariant, cs.surfaceVariant],
            rim: [cs.border],
            hexagon: true,
            emblem: cs.textSecondary,
            shine: false,
          ),
          centerY: centerY,
          radius: big ? 0.43 : 0.5,
          ribbon: false,
        ),
        child: Align(alignment: Alignment(0, centerY * 2 - 1), child: child),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter({
    required this.look,
    required this.centerY,
    required this.radius,
    required this.ribbon,
  });

  final CsBadgeLook look;

  /// Centre height and radius, as parts of the size.
  final double centerY;
  final double radius;
  final bool ribbon;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s * centerY);
    final rimWidth = math.max(1.2, s * 0.055);
    final r = s * radius - rimWidth / 2;
    final shape = look.hexagon ? _hexagon(c, r, s * 0.09) : _rosette(c, r);
    final bounds = shape.getBounds();

    // A soft coloured shadow under it.
    if (look.shine && s >= 30) {
      canvas.drawPath(
        shape.shift(Offset(0, s * 0.035)),
        Paint()
          ..color = look.fill.last.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05),
      );
    }

    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: look.fill,
        ).createShader(bounds),
    );

    if (look.shine) {
      canvas
        ..save()
        ..clipPath(shape);
      // Light from the top left.
      canvas.drawOval(
        Rect.fromLTWH(
          bounds.left - s * 0.2,
          bounds.top - s * 0.45,
          bounds.width * 1.1,
          bounds.height * 0.95,
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
          ).createShader(bounds),
      );
      canvas.restore();
      // An inner bevel line.
      if (s >= 30) {
        final inner = look.hexagon
            ? _hexagon(c, r * 0.8, s * 0.07)
            : _rosette(c, r * 0.8);
        canvas.drawPath(
          inner,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, s * 0.018)
            ..color = const Color(0x40FFFFFF),
        );
      }
    }

    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: look.rim.length == 1 ? [look.rim[0], look.rim[0]] : look.rim,
        ).createShader(bounds),
    );

    final metal = look.ribbon;
    if (ribbon && metal != null && look.stars > 0) {
      _ribbon(canvas, s, metal, look.stars);
    }
  }

  /// A metal ribbon across the bottom with the tier's stars.
  void _ribbon(Canvas canvas, double s, List<Color> metal, int stars) {
    final h = s * 0.2;
    final star = h * 0.62;
    final w = h * 0.9 + stars * star * 1.05;
    final rect = Rect.fromCenter(
      center: Offset(s / 2, s - h / 2 - s * 0.01),
      width: w,
      height: h,
    );
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
    canvas
      ..drawRRect(
        rr.shift(Offset(0, s * 0.015)),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02),
      )
      ..drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: metal,
          ).createShader(rect),
      )
      ..drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, s * 0.012)
          ..color = metal.last.withValues(alpha: 0.8),
      );
    final ink = Paint()..color = metal.last;
    final startX = rect.center.dx - (stars - 1) * star * 0.525;
    for (var i = 0; i < stars; i++) {
      canvas.drawPath(
        _star(Offset(startX + i * star * 1.05, rect.center.dy), star / 2),
        ink,
      );
    }
  }

  /// A pointy-top hexagon with rounded corners.
  static Path _hexagon(Offset c, double r, double round) {
    final pts = [
      for (var i = 0; i < 6; i++)
        c +
            Offset(
              r * math.cos(-math.pi / 2 + i * math.pi / 3),
              r * math.sin(-math.pi / 2 + i * math.pi / 3),
            ),
    ];
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final prev = pts[(i + 5) % 6];
      final cur = pts[i];
      final next = pts[(i + 1) % 6];
      final a = cur + _towards(cur, prev, round);
      final b = cur + _towards(cur, next, round);
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    return path..close();
  }

  /// A round medal with 14 soft scallops.
  static Path _rosette(Offset c, double r) {
    const bumps = 14;
    const steps = 112;
    final base = r / 1.05;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final rr = base * (1 + 0.05 * math.cos(bumps * t));
      final p = c + Offset(rr * math.cos(t), rr * math.sin(t));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  static Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(rr * math.cos(a), rr * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  static Offset _towards(Offset from, Offset to, double d) {
    final v = to - from;
    return v / v.distance * d;
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.look != look ||
      old.centerY != centerY ||
      old.radius != radius ||
      old.ribbon != ribbon;
}

/// Badge tiles in equal columns that fill the width (3 on a phone), so a
/// row never leaves a gap at the end.
class CsBadgeGrid extends StatelessWidget {
  const CsBadgeGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = (box.maxWidth / 104).floor().clamp(3, 5);
      final width = (box.maxWidth / columns).floorToDouble();
      return Wrap(
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    },
  );
}

/// One badge in a grid: the icon, its name, and a line below (the tier, how
/// to earn it, or "Only you see this"). Tappable.
class CsBadgeTile extends StatelessWidget {
  const CsBadgeTile({
    super.key,
    required this.badgeKey,
    required this.name,
    this.tier = 0,
    this.caption,
    this.locked = false,
    this.private = false,
    this.privateLabel,
    this.shown = false,
    this.onTap,
  });

  final String badgeKey;
  final String name;
  final int tier;

  /// Under the name ("Gold", "Needs 5 invites").
  final String? caption;
  final bool locked;

  /// Only the owner sees it: a small lock by the icon.
  final bool private;
  final String? privateLabel;

  /// This is the badge shown by the student's name.
  final bool shown;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CsRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CsSpace.xs,
            vertical: CsSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CsBadgeIcon(
                    badgeKey: badgeKey,
                    tier: tier,
                    size: 52,
                    locked: locked,
                  ),
                  if (private)
                    PositionedDirectional(
                      end: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.border),
                        ),
                        child: Icon(
                          CsIcons.lock,
                          size: 12,
                          color: cs.textSecondary,
                          semanticLabel: privateLabel,
                        ),
                      ),
                    ),
                  if (shown)
                    PositionedDirectional(
                      end: -2,
                      top: -2,
                      child: Icon(
                        CsIcons.checkCircle,
                        size: 18,
                        color: cs.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: CsSpace.xs + 2),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: locked ? cs.textSecondary : cs.textPrimary,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
