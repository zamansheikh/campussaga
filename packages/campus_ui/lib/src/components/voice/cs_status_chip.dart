import 'package:flutter/material.dart';

import '../../theme/cs_tokens.dart';
import '../../tokens/color_tokens.dart';

/// An issue's state, styled per DESIGN_SYSTEM.md §2: icon + text + colour,
/// never colour alone.
enum CsIssueTone {
  open(Icons.radio_button_unchecked),
  acknowledged(Icons.visibility_outlined),
  inProgress(Icons.autorenew),
  solved(Icons.check_circle),
  rejected(Icons.block),
  removed(Icons.delete_outline),
  review(Icons.hourglass_top);

  const CsIssueTone(this.icon);

  final IconData icon;

  CsStatusColors colors(CsColors cs) => switch (this) {
    open => cs.statusOpen,
    acknowledged => cs.statusAcknowledged,
    inProgress || review => cs.statusInProgress,
    solved => cs.statusSolved,
    rejected || removed => cs.statusRejected,
  };
}

class CsStatusChip extends StatelessWidget {
  const CsStatusChip({super.key, required this.tone, required this.label});

  final CsIssueTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = tone.colors(context.cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tone.icon, size: 14, color: c.fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                color: c.fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
