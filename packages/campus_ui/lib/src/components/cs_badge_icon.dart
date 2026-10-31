import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/cs_icons.dart';
import '../tokens/dimensions.dart';

/// The ring colour of a badge tier: bronze, silver and gold. The same in
/// light and dark (they sit on a soft fill that works on both).
abstract final class CsTierColors {
  static const bronze = Color(0xFFB4672A);
  static const silver = Color(0xFF8A94A6);
  static const gold = Color(0xFFD4A017);

  /// 1 bronze, 2 silver, 3 gold; null for badges without tiers (they get
  /// the brand colour).
  static Color? of(int tier) => switch (tier) {
    1 => bronze,
    2 => silver,
    3 => gold,
    _ => null,
  };
}

/// A badge as a round icon with a ring in its tier's colour (brand colour
/// for badges without tiers). [locked] greys it out. Small ones sit next
/// to names.
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

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final ring = locked ? cs.border : (CsTierColors.of(tier) ?? cs.primary);
    final fg = locked ? cs.textSecondary : ring;
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked ? cs.surfaceVariant : ring.withValues(alpha: 0.14),
        border: Border.all(color: ring, width: size >= 36 ? 2.5 : 1.5),
      ),
      child: Icon(CsIcons.badge(badgeKey), size: size * 0.5, color: fg),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: icon);
  }
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

  /// Width of a tile; three fit a phone.
  static const width = 96.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox(
      width: width,
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
