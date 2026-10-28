import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/clock.dart';
import '../../../classes/presentation/class_format.dart';
import '../voice_format.dart';
import 'voice_image.dart';

/// [CsIssueCard] for one issue.
class IssueListCard extends StatelessWidget {
  const IssueListCard({super.key, required this.card, this.onTap});

  final IssueCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = card;
    return CsIssueCard(
      category: c.category.wire,
      categoryLabel: categoryLabel(l10n, c.category),
      title: c.title,
      preview: c.preview,
      status: issueChip(l10n, c),
      meTooCount: countText(context, c.meTooCount),
      commentCount: countText(context, c.commentCount),
      timeLabel: agoText(context, c.createdAt, appNow()),
      authorLabel: issueAuthorLabel(l10n, c),
      anonymous: c.anonymous,
      voted: c.voted,
      thumbnail: c.thumbnail == null ? null : VoiceImage(c.thumbnail!),
      flags: [
        if (c.private)
          CsBadge(
            label: l10n.voicePrivate,
            icon: Icons.lock_outline,
            tone: CsBadgeTone.danger,
          ),
        if (c.locationLabel.isNotEmpty)
          CsBadge(
            label: c.locationLabel,
            icon: Icons.place_outlined,
            tone: CsBadgeTone.neutral,
          ),
      ],
      onTap: onTap,
    );
  }
}
