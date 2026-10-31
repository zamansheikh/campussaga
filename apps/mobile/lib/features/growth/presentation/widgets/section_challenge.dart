import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import 'goal_tile.dart';

/// On the campaign page: the section challenge. The goal (verified members
/// and classes earn the whole section the Champion section badge), the
/// team's prize for the top section when there is one, my section's
/// progress, and the top sections. Nothing shows when it can't load.
class SectionChallengeSection extends StatefulWidget {
  const SectionChallengeSection({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<SectionChallengeSection> createState() =>
      _SectionChallengeSectionState();
}

class _SectionChallengeSectionState extends State<SectionChallengeSection> {
  SectionBoard? _board;
  bool _all = false;

  /// Rows before "Show all".
  static const _few = 5;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final b = await getIt<GrowthRepository>().sections(widget.campaign.id);
      if (mounted) setState(() => _board = b);
    } on Failure {
      // Only an extra: say nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    if (board == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final goal = widget.campaign.sectionChallenge;
    final prize = widget.campaign.sectionPrize;
    final mine = board.mine;
    final rows = _all ? board.rows : board.rows.take(_few).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CsSectionTitle(title: l10n.sectionChallengeTitle),
        Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CsRadius.lg),
            side: BorderSide(color: cs.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The goal, and my section's way there.
              Padding(
                padding: const EdgeInsets.fromLTRB(CsSpace.md, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CsBadgeIcon(badgeKey: 'champion_section', size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.sectionChallengeGoal(goal.members, goal.slots),
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (prize.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              l10n.sectionChallengePrize(prize),
                              style: context.text.bodySmall?.copyWith(
                                color: const Color(0xFFF59E0B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (mine == null)
                            InkWell(
                              onTap: () => context.push(Routes.findClass),
                              child: Text(
                                l10n.sectionNoneYet,
                                style: context.text.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else ...[
                            Text(
                              '${l10n.sectionMine} · ${mine.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(
                                color: cs.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: GoalTile(
                                    label: l10n.sectionMembersLabel,
                                    have: mine.members,
                                    need: goal.members,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: GoalTile(
                                    label: l10n.sectionClassesLabel,
                                    have: mine.slots,
                                    need: goal.slots,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (final r in rows) ...[
                const Divider(height: 1),
                _SectionLine(row: r, mine: r.groupId == mine?.groupId),
              ],
              if (board.rows.length > _few) ...[
                const Divider(height: 1),
                TextButton(
                  onPressed: () => setState(() => _all = !_all),
                  child: Text(
                    _all ? l10n.sectionShowLess : l10n.sectionShowAll,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A section on the board: rank, name and university, verified members, and
/// the champion medal once it's a champion.
class _SectionLine extends StatelessWidget {
  const _SectionLine({required this.row, required this.mine});

  final SectionRow row;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Container(
      color: mine ? cs.primaryContainer.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.md, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${row.rank}',
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: row.rank <= 3 ? cs.primary : cs.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (row.university.isNotEmpty)
                  Text(
                    row.university,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: cs.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (row.champion) ...[
            CsBadgeIcon(
              badgeKey: 'champion_section',
              size: 20,
              semanticLabel: l10n.badgeNameChampionSection,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            l10n.sectionMembersCount(row.members),
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
