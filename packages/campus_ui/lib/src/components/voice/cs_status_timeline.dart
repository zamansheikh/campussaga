import 'package:flutter/material.dart';

import '../../theme/cs_tokens.dart';
import '../../tokens/dimensions.dart';
import '../cs_link_text.dart';
import 'cs_status_chip.dart';

/// One step of [CsStatusTimeline].
class CsTimelineStep {
  const CsTimelineStep({
    required this.tone,
    required this.title,
    required this.subtitle,
    this.note = '',
  });

  final CsIssueTone tone;
  final String title;

  /// Who and when ("Proctor Office · 28 Oct").
  final String subtitle;

  /// An official note, shown highlighted.
  final String note;
}

/// Vertical status history, oldest first.
class CsStatusTimeline extends StatelessWidget {
  const CsStatusTimeline({super.key, required this.steps});

  final List<CsTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Icon(
                        steps[i].tone.icon,
                        size: 20,
                        color: steps[i].tone.colors(cs).fg,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: cs.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < steps.length - 1 ? CsSpace.md : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].title, style: context.text.titleSmall),
                        Text(
                          steps[i].subtitle,
                          style: context.text.bodySmall?.copyWith(
                            color: cs.textSecondary,
                          ),
                        ),
                        if (steps[i].note.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.surfaceVariant,
                              borderRadius: BorderRadius.circular(CsRadius.sm),
                            ),
                            child: CsLinkText(
                              steps[i].note,
                              style: context.text.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
