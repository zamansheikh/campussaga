import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

/// One goal in a single line, "Your university  2/3", over a bar with a
/// segment per step (up to 10; more fill as a share). Used for the prize
/// race and the section challenge, side by side in equal columns.
class GoalTile extends StatelessWidget {
  const GoalTile({
    super.key,
    required this.label,
    required this.have,
    required this.need,
  });

  final String label;
  final int have;
  final int need;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final got = have.clamp(0, need);
    final done = got >= need;
    final segments = need.clamp(1, 10);
    // Past 10 steps, each segment stands for a share of the goal.
    final filled = need <= 10 ? got : (got * 10 / need).floor();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(CsRadius.sm),
        border: Border.all(color: cs.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
              ),
              Text(
                l10n.raceCount(got, need),
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: done ? cs.primary : cs.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              for (var i = 0; i < segments; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: i < filled
                          ? const Color(0xFFF59E0B)
                          : cs.surfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
