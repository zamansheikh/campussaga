import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';

enum CsBadgeTone { primary, success, neutral, accent, danger }

/// Small pill label, e.g. "Verified student".
class CsBadge extends StatelessWidget {
  const CsBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = CsBadgeTone.primary,
  });

  final String label;
  final IconData? icon;
  final CsBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final (fg, bg) = switch (tone) {
      CsBadgeTone.primary => (cs.onPrimaryContainer, cs.primaryContainer),
      CsBadgeTone.success => (cs.statusSolved.fg, cs.statusSolved.bg),
      CsBadgeTone.neutral => (cs.textSecondary, cs.surfaceVariant),
      CsBadgeTone.accent => (cs.statusInProgress.fg, cs.statusInProgress.bg),
      CsBadgeTone.danger => (cs.error, cs.error.withValues(alpha: 0.12)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
