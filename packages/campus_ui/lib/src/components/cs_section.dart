import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/dimensions.dart';

/// A titled group of rows on one rounded card, like a settings section.
class CsSection extends StatelessWidget {
  const CsSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Divider(indent: 64));
      rows.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.xs,
              0,
              CsSpace.xs,
              CsSpace.sm,
            ),
            child: Text(
              title!.toUpperCase(),
              style: context.text.labelMedium?.copyWith(
                letterSpacing: 0.8,
                color: cs.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CsRadius.lg),
            side: BorderSide(color: cs.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ],
    );
  }
}

/// One row: an icon on a tinted tile, title, optional subtitle and value,
/// and a chevron (or [trailing]).
class CsRow extends StatelessWidget {
  const CsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final fg = destructive ? cs.error : cs.onPrimaryContainer;
    final bg = destructive
        ? cs.error.withValues(alpha: 0.12)
        : cs.primaryContainer;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CsSpace.md,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: fg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: destructive ? cs.error : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: CsSpace.sm),
                Text(
                  value!,
                  style: context.text.bodyMedium?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: CsSpace.sm),
                trailing!,
              ] else if (showChevron && onTap != null) ...[
                const SizedBox(width: CsSpace.xs),
                Icon(Icons.chevron_right_rounded, color: cs.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
