import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/cs_tokens.dart';

/// "Me too" toggle with its count; a light haptic on tap.
class CsMeTooButton extends StatelessWidget {
  const CsMeTooButton({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final String count;
  final bool selected;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final fg = selected ? cs.onPrimary : cs.primary;
    return Semantics(
      button: true,
      toggled: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: selected ? cs.primary : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: cs.primary)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.front_hand : Icons.front_hand_outlined,
                  size: 18,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.text.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  count,
                  style: context.text.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
