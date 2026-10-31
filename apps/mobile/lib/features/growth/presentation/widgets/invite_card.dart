import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/di.dart';
import '../invite_share.dart';

/// On Profile: "Invite friends". How many I invited and how many joined,
/// a Share button with my personal link, and the friends who haven't
/// counted yet. Nothing shows when it can't load (an older server).
class InviteCard extends StatefulWidget {
  const InviteCard({super.key, this.reveal = false});

  /// Scroll to it once it shows (opened from a push).
  final bool reveal;

  @override
  State<InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<InviteCard> {
  ReferralStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<GrowthRepository>()) return;
    try {
      final s = await getIt<GrowthRepository>().referrals();
      if (!mounted) return;
      setState(() => _stats = s);
      if (widget.reveal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(
              Scrollable.ensureVisible(context, duration: CsMotion.normal),
            );
          }
        });
      }
    } on Failure {
      // Only an extra: say nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.lg),
      child: CsSection(
        title: l10n.inviteFriendsTitle,
        children: [
          Padding(
            padding: const EdgeInsets.all(CsSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inviteStats(stats.invited, stats.joined),
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: CsSpace.xs),
                Text(
                  l10n.inviteCountsRule,
                  style: context.text.bodySmall?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
                const SizedBox(height: CsSpace.md),
                FilledButton.icon(
                  onPressed: () => shareMyInvite(context, stats: stats),
                  icon: const Icon(CsIcons.share),
                  label: Text(l10n.inviteShareButton),
                ),
              ],
            ),
          ),
          if (stats.pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(CsSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.invitePendingTitle,
                    style: context.text.labelLarge?.copyWith(
                      color: cs.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CsSpace.sm),
                  for (final p in stats.pending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: CsSpace.xs),
                      child: Text(
                        l10n.invitePendingLine(
                          p.name.isEmpty ? l10n.unnamedStudent : p.name,
                          p.verified
                              ? l10n.inviteStatusVerified
                              : l10n.inviteStatusNotVerified,
                          p.activeDays,
                        ),
                        style: context.text.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
