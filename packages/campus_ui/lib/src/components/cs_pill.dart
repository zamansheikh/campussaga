import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/cs_icons.dart';
import '../tokens/dimensions.dart';

/// One size of pill for a row of facts and links ("Dhaka", "Public",
/// "Website ↗"), so a row never mixes heights or shapes. Without [onTap]
/// it is a quiet fact; with it, a tinted link that shows [trailing]
/// (an "opens elsewhere" arrow by default).
class CsPill extends StatelessWidget {
  const CsPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.trailing = CsIcons.openExternal,
    this.highlight = false,
    this.tooltip,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Shown after the label on tappable pills (null: none).
  final IconData? trailing;

  /// A fact worth noticing ("Your campus"): tinted, not tappable.
  final bool highlight;
  final String? tooltip;

  /// Every pill is this tall.
  static const height = 34.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tappable = onTap != null;
    final tinted = tappable || highlight;
    final fg = tinted ? cs.onPrimaryContainer : cs.textSecondary;
    final pill = Material(
      color: tinted
          ? cs.primaryContainer.withValues(alpha: tappable ? 0.55 : 0.9)
          : cs.surfaceVariant,
      shape: StadiumBorder(
        side: BorderSide(color: tappable ? cs.border : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CsSpace.sm + 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: tappable ? cs.primary : fg),
                  const SizedBox(width: 6),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(
                      color: tinted ? cs.textPrimary : fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (tappable && trailing != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailing, size: 14, color: cs.textSecondary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: tappable,
      child: tooltip == null ? pill : Tooltip(message: tooltip, child: pill),
    );
  }
}
