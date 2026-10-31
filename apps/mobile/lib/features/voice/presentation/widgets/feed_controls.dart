import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/feed_cubit.dart';
import '../voice_format.dart';

/// For you · Latest · Ask · Issues, pinned under the app bar.
class FeedTabsHeader extends SliverPersistentHeaderDelegate {
  FeedTabsHeader({
    required this.tab,
    required this.onTab,
    required this.labels,
    required this.background,
  });

  final FeedTab tab;
  final void Function(FeedTab) onTab;
  final Map<FeedTab, String> labels;
  final Color background;

  static const _height = 60.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(FeedTabsHeader old) =>
      old.tab != tab || old.labels != labels || old.background != background;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final cs = context.cs;
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(
        CsSpace.md,
        CsSpace.sm + 2,
        CsSpace.md,
        CsSpace.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(CsRadius.full),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final t in labels.keys)
              Expanded(
                child: Semantics(
                  selected: t == tab,
                  button: true,
                  child: GestureDetector(
                    onTap: () => onTab(t),
                    child: AnimatedContainer(
                      duration: CsMotion.fast,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t == tab ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(CsRadius.full),
                      ),
                      child: Text(
                        labels[t]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: t == tab ? cs.onPrimary : cs.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Topic chips; on the Issues tab also Open / Solved (and, for officials,
/// the private safety reports).
class FeedTopics extends StatelessWidget {
  const FeedTopics({super.key, this.staff = false});

  final bool staff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<FeedCubit>();
    final s = context.watch<FeedCubit>().state;
    final issues = s.tab == FeedTab.issues;
    final topics = issues
        ? [
            for (final c in IssueCategory.forIssues)
              if (c != IssueCategory.safety) c,
          ]
        : IssueCategory.forPosts;
    return SizedBox(
      height: 52,
      child: ListView(
        // Each tab starts at its first chip.
        key: ValueKey(s.tab),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CsSpace.md,
          vertical: CsSpace.sm,
        ),
        children: [
          if (issues) ...[
            ChoiceChip(
              label: Text(l10n.campusIssuesOpen),
              selected: !s.solved,
              showCheckmark: false,
              onSelected: (_) => cubit.setSolved(false),
            ),
            const SizedBox(width: CsSpace.sm),
            ChoiceChip(
              avatar: const Icon(CsIcons.checkCircle, size: 18),
              label: Text(l10n.voiceSortSolved),
              selected: s.solved,
              showCheckmark: false,
              onSelected: (_) => cubit.setSolved(true),
            ),
            if (staff) ...[
              const SizedBox(width: CsSpace.sm),
              FilterChip(
                avatar: const Icon(CsIcons.lock, size: 18),
                label: Text(l10n.voiceSafetyReports),
                selected: s.safety,
                onSelected: cubit.setSafety,
              ),
            ],
            const SizedBox(width: CsSpace.sm),
            const VerticalDivider(width: CsSpace.sm),
            const SizedBox(width: CsSpace.sm),
          ],
          ChoiceChip(
            label: Text(l10n.voiceAllCategories),
            selected: s.category == null,
            showCheckmark: false,
            onSelected: (_) => cubit.setCategory(null),
          ),
          for (final c in topics) ...[
            const SizedBox(width: CsSpace.sm),
            ChoiceChip(
              avatar: Icon(
                CsCategoryStyle.icon(c.wire),
                size: 18,
                color: CsCategoryStyle.color(c.wire),
              ),
              label: Text(categoryLabel(l10n, c)),
              selected: s.category == c,
              showCheckmark: false,
              onSelected: (_) => cubit.setCategory(s.category == c ? null : c),
            ),
          ],
        ],
      ),
    );
  }
}
