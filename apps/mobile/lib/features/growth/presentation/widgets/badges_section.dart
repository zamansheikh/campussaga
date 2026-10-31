import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../growth_text.dart';

/// My badges. [compact] (Profile): one row of the earned ones and "See
/// all", which opens the full list. Full (the Badges page): every earned
/// badge with its tier, and the ones still to earn, greyed, saying how.
/// Tap one for the details and to show it by my name. Nothing shows when
/// it can't load.
class BadgesSection extends StatefulWidget {
  const BadgesSection({super.key, this.reveal = false, this.compact = false});

  /// Scroll to it once it shows (opened from a push).
  final bool reveal;
  final bool compact;

  @override
  State<BadgesSection> createState() => _BadgesSectionState();
}

class _BadgesSectionState extends State<BadgesSection> {
  MyBadges? _badges;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<GrowthRepository>()) return;
    try {
      final b = await getIt<GrowthRepository>().myBadges();
      if (!mounted) return;
      setState(() => _badges = b);
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

  Future<void> _open(EarnedBadge? earned, BadgeInfo? info, String key) async {
    final badges = _badges;
    if (badges == null) return;
    final auth = context.read<AuthBloc>();
    final result = await showModalBottomSheet<_Featured>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BadgeSheet(
        badgeKey: key,
        earned: earned,
        info: info,
        featured: badges.featured,
      ),
    );
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.badge == null ? l10n.badgeNoLongerShown : l10n.badgeNowShown,
        ),
      ),
    );
    setState(() => _badges = badges.withFeatured(result.badge));
    final user = auth.state.user;
    if (user != null) {
      auth.add(
        AuthProfileUpdated(
          user.withGrowth(
            featuredBadge: result.badge,
            clearFeaturedBadge: result.badge == null,
          ),
        ),
      );
    }
  }

  Future<void> _seeAll() async {
    await context.push(Routes.badges);
    if (mounted) await _load(); // the shown badge may have changed
  }

  Widget _compact(BuildContext context, MyBadges badges) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final locked = badges.locked.length;
    final total = badges.badges.length + locked;
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CsSectionTitle(
            title: l10n.badgesTitle,
            action: TextButton(
              onPressed: _seeAll,
              child: Text(l10n.badgesSeeAll(badges.badges.length, total)),
            ),
          ),
          Material(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CsRadius.lg),
              side: BorderSide(color: cs.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CsSpace.xs,
                vertical: CsSpace.sm,
              ),
              // As many equal slots as fit (4 on most phones), so nothing
              // is cut at the edge; the last one is "+N" when more are earned.
              child: LayoutBuilder(
                builder: (context, box) {
                  final slots = (box.maxWidth / 84).floor().clamp(4, 6);
                  final width = box.maxWidth / slots;
                  final earned = [
                    ...badges.badges.where(
                      (b) => b.key == badges.featured?.key,
                    ),
                    ...badges.badges.where(
                      (b) => b.key != badges.featured?.key,
                    ),
                  ];
                  final fits = earned.length + (locked > 0 ? 1 : 0) <= slots;
                  final shown = fits ? earned : earned.take(slots - 1);
                  final more = earned.length - shown.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final b in shown)
                        _MiniBadge(
                          width: width,
                          icon: CsBadgeIcon(
                            badgeKey: b.key,
                            tier: b.tier,
                            size: 52,
                            semanticLabel: badgeName(l10n, b.key),
                          ),
                          label: badgeName(l10n, b.key),
                          shown: badges.featured?.key == b.key,
                          onTap: () => _open(b, badges.info(b.key), b.key),
                        ),
                      if (more > 0)
                        _MiniBadge(
                          width: width,
                          icon: CsBadgeSlot(
                            size: 52,
                            child: Text(
                              l10n.badgesPlus(more),
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          label: l10n.badgesMore,
                          muted: true,
                          onTap: _seeAll,
                        )
                      else if (locked > 0)
                        _MiniBadge(
                          width: width,
                          icon: CsBadgeSlot(
                            size: 52,
                            child: Icon(
                              CsIcons.lock,
                              size: 20,
                              color: cs.textSecondary,
                            ),
                          ),
                          label: l10n.badgesToEarn(locked),
                          muted: true,
                          onTap: _seeAll,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badges = _badges;
    if (badges == null) return const SizedBox.shrink();
    if (widget.compact) return _compact(context, badges);
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final locked = badges.locked;
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // On the Badges page: the app bar already says "Badges".
          CsSectionTitle(title: l10n.badgesEarnedTitle(badges.badges.length)),
          Material(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CsRadius.lg),
              side: BorderSide(color: cs.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(CsSpace.sm),
              child: badges.badges.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(CsSpace.sm),
                      child: Text(
                        l10n.badgesEmpty,
                        style: context.text.bodyMedium?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                    )
                  : CsBadgeGrid(
                      children: [
                        for (final b in badges.badges)
                          CsBadgeTile(
                            badgeKey: b.key,
                            name: badgeName(l10n, b.key),
                            tier: b.tier,
                            caption: b.private
                                ? l10n.badgePrivateNote
                                : tierName(l10n, b.tier),
                            private: b.private,
                            privateLabel: l10n.badgePrivateNote,
                            shown: badges.featured?.key == b.key,
                            onTap: () => _open(b, badges.info(b.key), b.key),
                          ),
                      ],
                    ),
            ),
          ),
          if (locked.isNotEmpty) ...[
            const SizedBox(height: CsSpace.lg),
            CsSection(
              title: l10n.badgesLockedTitle,
              children: [
                for (final i in locked)
                  _LockedRow(info: i, onTap: () => _open(null, i, i.key)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One badge in the Profile row: the icon and its name under it, on one
/// line.
class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
    this.shown = false,
    this.muted = false,
  });

  final double width;
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  /// Shown by my name: the label is bold.
  final bool shown;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(CsRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            children: [
              icon,
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(
                  color: muted ? cs.textSecondary : cs.textPrimary,
                  fontWeight: shown ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A badge still to earn: greyed, with how to earn it.
class _LockedRow extends StatelessWidget {
  const _LockedRow({required this.info, required this.onTap});

  final BadgeInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final tiers = tiersLine(l10n, info.tiers);
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
              CsBadgeIcon(badgeKey: info.key, size: 34, locked: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badgeName(l10n, info.key),
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: cs.textSecondary,
                      ),
                    ),
                    Text(
                      [
                        badgeHow(l10n, info.key),
                        ?tiers,
                        if (info.private) l10n.badgePrivateNote,
                      ].where((t) => t.isNotEmpty).join('\n'),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (info.private) ...[
                const SizedBox(width: CsSpace.sm),
                Icon(CsIcons.lock, size: 16, color: cs.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// What the sheet gives back: the badge shown by the name now (or none).
class _Featured {
  const _Featured(this.badge);

  final BadgeRef? badge;
}

class _BadgeSheet extends StatefulWidget {
  const _BadgeSheet({
    required this.badgeKey,
    required this.earned,
    required this.info,
    required this.featured,
  });

  final String badgeKey;
  final EarnedBadge? earned;
  final BadgeInfo? info;
  final BadgeRef? featured;

  @override
  State<_BadgeSheet> createState() => _BadgeSheetState();
}

class _BadgeSheetState extends State<_BadgeSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _set(bool show) async {
    final l10n = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final now = await getIt<GrowthRepository>().setFeaturedBadge(
        show ? widget.badgeKey : null,
      );
      nav.pop(_Featured(now));
    } on Failure catch (f) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = growthErrorText(l10n, f);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final earned = widget.earned;
    final key = widget.badgeKey;
    final private = earned?.private ?? widget.info?.private ?? false;
    final shown = widget.featured?.key == key;
    final tier = earned?.tier ?? 0;
    final tiers = tiersLine(l10n, widget.info?.tiers ?? const []);
    final when = earned?.earnedAt;
    final line = [
      ?tierName(l10n, tier),
      if (when != null)
        l10n.badgeEarnedOn(DateFormat.yMMMd(l10n.localeName).format(when)),
    ].join(' · ');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.screen,
          0,
          CsSpace.screen,
          CsSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CsBadgeIcon(
                badgeKey: key,
                tier: tier,
                size: 72,
                locked: earned == null,
              ),
            ),
            const SizedBox(height: CsSpace.md),
            Text(
              badgeName(l10n, key),
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
            if (line.isNotEmpty) ...[
              const SizedBox(height: CsSpace.xs),
              Text(
                line,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: CsSpace.md),
            Text(
              badgeHow(l10n, key),
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            if (tiers != null) ...[
              const SizedBox(height: CsSpace.xs),
              Text(
                tiers,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: CsSpace.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: CsSpace.sm,
              runSpacing: CsSpace.sm,
              children: [
                if (earned == null)
                  CsPill(icon: CsIcons.lock, label: l10n.badgeLocked),
                if (private)
                  CsPill(icon: CsIcons.hidden, label: l10n.badgePrivateNote),
                if (shown)
                  CsPill(
                    icon: CsIcons.checkCircle,
                    label: l10n.badgeShownByName,
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: CsSpace.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: cs.error),
              ),
            ],
            if (earned != null && !private) ...[
              const SizedBox(height: CsSpace.md),
              if (shown)
                OutlinedButton(
                  onPressed: _busy ? null : () => _set(false),
                  child: Text(l10n.badgeStopShowing),
                )
              else
                FilledButton(
                  onPressed: _busy ? null : () => _set(true),
                  child: Text(l10n.badgeShowByName),
                ),
            ],
            if (earned != null && private) ...[
              const SizedBox(height: CsSpace.md),
              Text(
                l10n.badgePrivateCant,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
