import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/version/version_gate_cubit.dart';

/// Everything the app does beyond the main tabs, as a grid of cards. New
/// features land here first; ones being built show "Coming soon".
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final voice = context.select(
      (VersionGateCubit g) => g.state.feature('campusVoice'),
    );
    final blood = context.select(
      (VersionGateCubit g) => g.state.feature('bloodDonation'),
    );
    final tools = [
      if (blood)
        _Feature(
          icon: CsIcons.bloodFill,
          title: l10n.bloodTitle,
          hint: l10n.bloodHint,
          onTap: () => context.push(Routes.blood),
        ),
      _Feature(
        icon: CsIcons.groups,
        title: l10n.classGroups,
        hint: l10n.exploreGroupsHint,
        onTap: () => context.push(Routes.groups),
      ),
      _Feature(
        icon: CsIcons.reminders,
        title: l10n.reminders,
        hint: l10n.exploreRemindersHint,
        onTap: () => context.push(Routes.reminders),
      ),
      _Feature(
        icon: CsIcons.cgpa,
        title: l10n.cgpaTitle,
        hint: l10n.cgpaHint,
        onTap: () => context.push(Routes.cgpa),
      ),
      if (voice)
        _Feature(
          icon: CsIcons.myIssues,
          title: l10n.campusMyPosts,
          hint: l10n.exploreIssuesHint,
          onTap: () => context.push(Routes.campusMine),
        ),
      _Feature(
        icon: CsIcons.bus,
        title: l10n.busRoutesTitle,
        hint: l10n.busRoutesBody,
        onTap: () => context.push(Routes.bus),
      ),
    ];
    final soon = [
      _Feature(
        icon: CsIcons.teacherReviews,
        title: l10n.teacherReviewsTitle,
        hint: l10n.teacherReviewsBody,
        soon: true,
      ),
      _Feature(
        icon: CsIcons.rankings,
        title: l10n.rankingsTitle,
        hint: l10n.rankingsBody,
        soon: true,
      ),
      _Feature(
        icon: CsIcons.visitCampus,
        title: l10n.visitCampusTitle,
        hint: l10n.visitCampusBody,
        soon: true,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                CsSpace.screen,
                CsSpace.lg,
                CsSpace.screen,
                CsSpace.sm,
              ),
              sliver: SliverList.list(
                children: [
                  Text(l10n.exploreTitle, style: context.text.headlineSmall),
                  const SizedBox(height: CsSpace.xs),
                  Text(
                    l10n.exploreSubtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.cs.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _title(context, l10n.exploreYourTools),
            _grid(tools),
            _title(context, l10n.exploreComingSoon),
            _grid(soon),
            const SliverToBoxAdapter(child: SizedBox(height: CsSpace.xl)),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      CsSpace.screen + CsSpace.xs,
      CsSpace.lg,
      CsSpace.screen,
      CsSpace.sm,
    ),
    sliver: SliverToBoxAdapter(
      child: Text(
        text.toUpperCase(),
        style: context.text.labelMedium?.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: context.cs.textSecondary,
        ),
      ),
    ),
  );

  Widget _grid(List<_Feature> items) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: CsSpace.screen),
    sliver: SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: CsSpace.sm + 4,
        crossAxisSpacing: CsSpace.sm + 4,
        mainAxisExtent: 168,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _FeatureCard(items[i]),
    ),
  );
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.hint,
    this.onTap,
    this.soon = false,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback? onTap;
  final bool soon;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.f);

  final _Feature f;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Material(
      color: f.soon ? cs.surfaceVariant : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: f.soon ? () => _showSoon(context, f) : f.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(CsRadius.md),
                ),
                child: Icon(f.icon, color: cs.onPrimaryContainer),
              ),
              const Spacer(),
              if (f.soon) ...[
                CsBadge(label: l10n.comingSoon, tone: CsBadgeTone.accent),
                const SizedBox(height: 6),
              ],
              Text(
                f.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                f.hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a coming feature will do.
Future<void> _showSoon(BuildContext context, _Feature f) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.lg,
          0,
          CsSpace.lg,
          CsSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(f.icon, color: sheet.cs.primary, size: 28),
                const SizedBox(width: CsSpace.sm),
                Expanded(child: Text(f.title, style: sheet.text.titleLarge)),
                CsBadge(label: l10n.comingSoon, tone: CsBadgeTone.accent),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            Text(f.hint, style: sheet.text.bodyLarge),
            const SizedBox(height: CsSpace.md),
            Text(
              l10n.comingSoonNote,
              style: sheet.text.bodyMedium?.copyWith(
                color: sheet.cs.textSecondary,
              ),
            ),
            const SizedBox(height: CsSpace.lg),
            FilledButton(
              onPressed: () => Navigator.of(sheet).pop(),
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      ),
    ),
  );
}
