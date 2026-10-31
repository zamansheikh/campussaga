import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../growth_text.dart';
import '../invite_share.dart';

/// On Profile: "Invite friends". The friends who joined (faces) and the
/// counts, a Share button with my personal link, progress to the next
/// Connector medal, what a friend is worth while a campaign runs, and the
/// friends who haven't counted yet. Nothing shows when it can't load.
class InviteCard extends StatefulWidget {
  const InviteCard({super.key, this.reveal = false});

  /// Scroll to it once it shows (opened from a push).
  final bool reveal;

  @override
  State<InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<InviteCard> {
  ReferralStats? _stats;

  /// A live campaign, for "+10 points a friend".
  Campaign? _campaign;

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
    try {
      final lang = mounted
          ? Localizations.localeOf(context).languageCode
          : 'en';
      final list = await getIt<GrowthRepository>().campaigns(lang: lang);
      final now = appNow();
      final live = [
        for (final c in list)
          if (c.isLive(now)) c,
      ];
      if (mounted && live.isNotEmpty) setState(() => _campaign = live.first);
    } on Failure {
      // The hint is only an extra.
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final campaign = _campaign;
    final next = _nextTier(stats.joined);
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.lg),
      child: CsSection(
        title: l10n.inviteFriendsTitle,
        children: [
          // Who joined (faces), the counts, and a small Share button.
          Padding(
            padding: const EdgeInsets.fromLTRB(CsSpace.md, 12, 12, 12),
            child: Row(
              children: [
                _Faces(names: stats.recent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.inviteStats(stats.invited, stats.joined),
                        style: context.text.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.inviteCountsRule,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => shareMyInvite(context, stats: stats),
                  icon: const Icon(CsIcons.share, size: 18),
                  label: Text(l10n.campusShare),
                ),
              ],
            ),
          ),
          // On the way to the next Connector medal.
          if (next != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CsSpace.md,
                10,
                CsSpace.md,
                12,
              ),
              child: Row(
                children: [
                  CsBadgeIcon(badgeKey: 'connector', tier: next.$2, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Progress(value: stats.joined / next.$1),
                        const SizedBox(height: 6),
                        Text(
                          l10n.inviteNextTier(
                            next.$1 - stats.joined,
                            tierName(l10n, next.$2) ?? '',
                          ),
                          style: context.text.bodySmall?.copyWith(
                            color: cs.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // While a campaign runs: what a friend is worth.
          if (campaign != null && campaign.scoring.invite > 0)
            InkWell(
              onTap: () => context.push(Routes.campaign(campaign.id)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(CsSpace.md, 10, 8, 10),
                child: Row(
                  children: [
                    const Icon(
                      CsIcons.trophy,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: CsSpace.sm),
                    Expanded(
                      child: Text(
                        l10n.invitePointsHint(
                          campaign.scoring.invite,
                          campaign.scoring.otherCampus,
                        ),
                        style: context.text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      CsIcons.chevronRight,
                      size: 20,
                      color: cs.textSecondary,
                    ),
                  ],
                ),
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

/// Connector medal thresholds (bronze, silver, gold), as on the server.
const _connectorTiers = [5, 25, 100];

/// The next Connector tier to reach: (friends needed, tier), or null at gold.
(int, int)? _nextTier(int joined) {
  for (var i = 0; i < _connectorTiers.length; i++) {
    if (joined < _connectorTiers[i]) return (_connectorTiers[i], i + 1);
  }
  return null;
}

/// Up to three friends who joined, as overlapping faces; an invite icon on
/// the connector colours before anyone has.
class _Faces extends StatelessWidget {
  const _Faces({required this.names});

  final List<String> names;

  static const _size = 34.0;

  @override
  Widget build(BuildContext context) {
    final shown = names.where((n) => n.trim().isNotEmpty).take(3).toList();
    if (shown.isEmpty) {
      final (light, dark) = CsBadgeColors.of('connector');
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [light, dark],
          ),
        ),
        child: const Icon(CsIcons.invite, size: 20, color: Colors.white),
      );
    }
    final ring = context.cs.surface;
    return SizedBox(
      width: _size + (shown.length - 1) * (_size * 0.6),
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _size * 0.6,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
                child: CsAvatar(name: shown[i], size: _size - 3),
              ),
            ),
        ],
      ),
    );
  }
}

/// A slim bar in the connector colours.
class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final (light, dark) = CsBadgeColors.of('connector');
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: context.cs.surfaceVariant),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.04, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [light, dark]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
