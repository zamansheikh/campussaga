import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../invite_share.dart';

/// The ways to earn points in a campaign, with my progress: invites first,
/// then the things that make the app useful (my section, blood donors,
/// live buses, a CR's routine). Each row opens where you do it.
class MissionsSection extends StatelessWidget {
  const MissionsSection({super.key, required this.campaign, this.live = true});

  final Campaign campaign;

  /// While live, rows open where you earn; after, they only show.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final missions = campaignMissions(campaign);
    if (missions.isEmpty) return const SizedBox.shrink();
    final bonuses = [
      for (final m in missions)
        if (_inviteBonuses.contains(m.key)) m,
    ];
    final hasInvite = missions.any((m) => m.key == 'invite');
    final rows = [
      for (final m in missions)
        if (!hasInvite || !_inviteBonuses.contains(m.key)) m,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CsSectionTitle(
          title: l10n.campaignWaysTitle,
          action: campaign.myScore > 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    l10n.campaignScore(campaign.myScore),
                    style: context.text.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : null,
        ),
        Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CsRadius.lg),
            side: BorderSide(color: cs.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (campaign.scoring.hasRace) ...[
                _RaceRow(
                  campaign: campaign,
                  onTap: live ? () => unawaited(shareMyInvite(context)) : null,
                ),
                const Divider(indent: 70),
              ],
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(indent: 70),
                _MissionRow(
                  mission: rows[i],
                  campaign: campaign,
                  // The invite bonuses ride on the invite row as chips.
                  bonuses: rows[i].key == 'invite' ? bonuses : const [],
                  onTap: live
                      ? () => openMission(context, campaign, rows[i])
                      : null,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(CsSpace.xs, CsSpace.sm, 0, 0),
          child: Text(
            l10n.inviteCountsRule,
            style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Extras per invited friend, shown on the invite row.
const _inviteBonuses = {'otherCampus', 'pioneer', 'friendSection'};

/// The campaign's missions: from the server with my progress, or (a list
/// item, an older server) from its point values with none.
List<CampaignMission> campaignMissions(Campaign c) {
  if (c.missions.isNotEmpty) return c.missions;
  final s = c.scoring;
  return [
    if (s.invite > 0)
      CampaignMission(key: 'invite', points: s.invite, per: MissionPer.friend),
    if (s.otherCampus > 0)
      CampaignMission(
        key: 'otherCampus',
        points: s.otherCampus,
        per: MissionPer.friend,
      ),
    if (s.pioneer > 0)
      CampaignMission(
        key: 'pioneer',
        points: s.pioneer,
        per: MissionPer.friend,
      ),
    if (s.friendSection > 0)
      CampaignMission(
        key: 'friendSection',
        points: s.friendSection,
        per: MissionPer.friend,
      ),
    if (s.joinSection > 0)
      CampaignMission(
        key: 'joinSection',
        points: s.joinSection,
        per: MissionPer.once,
        max: 1,
      ),
    if (s.bloodDonor > 0)
      CampaignMission(
        key: 'bloodDonor',
        points: s.bloodDonor,
        per: MissionPer.once,
        max: 1,
      ),
    if (s.busShare > 0 && s.busShareDays > 0)
      CampaignMission(
        key: 'busShare',
        points: s.busShare,
        per: MissionPer.day,
        max: s.busShareDays,
      ),
    if (s.sectionSetup > 0 && s.sectionSetupMax > 0)
      CampaignMission(
        key: 'sectionSetup',
        points: s.sectionSetup,
        per: MissionPer.section,
        max: s.sectionSetupMax,
      ),
  ];
}

/// The first mission I haven't done yet that I can do myself, for the
/// Today nudge: a once mission, my section, a bus day; else inviting.
CampaignMission? nextMission(Campaign c) {
  final all = campaignMissions(c);
  // Without my progress (an older server) only inviting is a safe nudge.
  if (c.missions.isEmpty) {
    return all.where((m) => m.key == 'invite').firstOrNull;
  }
  for (final key in ['joinSection', 'bloodDonor', 'sectionSetup', 'busShare']) {
    for (final m in all) {
      if (m.key != key || m.done) continue;
      // Setting up a section is for CRs: only when I run one.
      if (key == 'sectionSetup' && c.section == null) continue;
      // Bus days only when there's progress to build on.
      if (key == 'busShare' && m.count == 0) continue;
      return m;
    }
  }
  for (final m in all) {
    if (m.key == 'invite') return m;
  }
  return null;
}

String missionTitle(AppLocalizations l10n, String key) => switch (key) {
  'invite' => l10n.missionInvite,
  'otherCampus' => l10n.missionOtherCampus,
  'pioneer' => l10n.missionPioneer,
  'friendSection' => l10n.missionFriendSection,
  'joinSection' => l10n.missionJoinSection,
  'bloodDonor' => l10n.missionBloodDonor,
  'busShare' => l10n.missionBusShare,
  'sectionSetup' => l10n.missionSectionSetup,
  _ => key,
};

/// How a mission earns ("+10 for each friend who joins").
String missionRule(AppLocalizations l10n, CampaignMission m, Campaign c) =>
    switch (m.key) {
      'invite' => l10n.missionInviteRule(m.points),
      'otherCampus' || 'friendSection' => l10n.missionExtraRule(m.points),
      'pioneer' => l10n.missionPioneerRule(m.points, c.scoring.pioneerFirst),
      'busShare' => l10n.missionBusShareRule(m.points, m.max ?? 0),
      'sectionSetup' => l10n.missionSectionSetupRule(m.points, m.max ?? 0),
      _ => l10n.missionOnceRule(m.points),
    };

/// My progress on a mission, or null before any.
String? missionProgress(AppLocalizations l10n, CampaignMission m) {
  if (m.per == MissionPer.once) {
    return m.count > 0 ? l10n.missionDone(m.earned) : null;
  }
  if (m.count == 0) return null;
  return switch (m.per) {
    MissionPer.friend => l10n.missionFriends(m.count, m.earned),
    MissionPer.day => l10n.missionDays(m.count, m.max ?? m.count, m.earned),
    _ => l10n.missionSections(m.count, m.max ?? m.count, m.earned),
  };
}

/// Opens where the mission is done.
void openMission(BuildContext context, Campaign c, CampaignMission m) {
  switch (m.key) {
    case 'joinSection':
      unawaited(context.push(Routes.findClass));
    case 'bloodDonor':
      unawaited(context.push(Routes.blood));
    case 'busShare':
      unawaited(context.push(Routes.bus));
    case 'sectionSetup':
      final s = c.section;
      unawaited(
        context.push(s == null ? Routes.groups : Routes.group(s.groupId)),
      );
    default:
      unawaited(shareMyInvite(context));
  }
}

/// A mission: a gold coin with its points (a green check once done), the
/// title, how it earns, and my progress.
class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.mission,
    required this.campaign,
    required this.onTap,
    this.bonuses = const [],
  });

  final CampaignMission mission;
  final Campaign campaign;
  final VoidCallback? onTap;

  /// Extras per friend (on the invite row).
  final List<CampaignMission> bonuses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final m = mission;
    // The invite row counts its extras in what I earned.
    final earned = m.earned + bonuses.fold<int>(0, (a, b) => a + b.earned);
    final progress = missionProgress(
      l10n,
      bonuses.isEmpty
          ? m
          : CampaignMission(
              key: m.key,
              points: m.points,
              per: m.per,
              count: m.count,
              max: m.max,
              earned: earned,
            ),
    );
    final section = campaign.section;
    final sectionLine = m.key == 'sectionSetup' && section != null
        ? l10n.missionSectionProgress(
            section.name,
            section.slots.clamp(0, CampaignSectionProgress.need),
            section.members.clamp(0, CampaignSectionProgress.need),
          )
        : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(CsSpace.md, 12, 12, 12),
        child: Row(
          children: [
            _Coin(points: m.points, done: m.done),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    missionTitle(l10n, m.key),
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    missionRule(l10n, m, campaign),
                    style: context.text.bodySmall?.copyWith(
                      color: cs.textSecondary,
                    ),
                  ),
                  if (bonuses.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.missionInviteBonuses,
                      style: context.text.labelSmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final b in bonuses)
                          _BonusChip(label: _bonusLabel(l10n, b)),
                      ],
                    ),
                  ],
                  if (sectionLine != null || progress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sectionLine ?? progress!,
                      style: context.text.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null && !m.done) ...[
              const SizedBox(width: CsSpace.xs),
              Icon(CsIcons.chevronRight, color: cs.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

/// "+10" on a gold coin; a teal check once the mission is done.
class _Coin extends StatelessWidget {
  const _Coin({required this.points, required this.done});

  final int points;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: done
              ? const [Color(0xFF5EEAD4), Color(0xFF0F766E)]
              : const [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
        ),
        border: Border.all(
          color: done ? const Color(0xFF99F6E4) : const Color(0xFFFEF3C7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (done ? const Color(0xFF0F766E) : const Color(0xFFB45309))
                .withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: done
          ? const Icon(CsIcons.check, size: 22, color: Colors.white)
          : Text(
              l10n.badgesPlus(points),
              style: context.text.labelMedium?.copyWith(
                color: const Color(0xFF422006),
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

String _bonusLabel(AppLocalizations l10n, CampaignMission b) => switch (b.key) {
  'otherCampus' => l10n.missionBonusOtherCampus(b.points),
  'pioneer' => l10n.missionBonusPioneer(b.points),
  _ => l10n.missionBonusSection(b.points),
};

/// A small amber-outlined extra ("+5 other university").
class _BonusChip extends StatelessWidget {
  const _BonusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0x1FF59E0B),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0x66F59E0B)),
    ),
    child: Text(
      label,
      style: context.text.labelSmall?.copyWith(
        color: context.cs.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// "Enter the prize race": the friends from other universities needed to
/// be ranked, and how many I have. Tinted gold until I'm in.
class _RaceRow extends StatelessWidget {
  const _RaceRow({required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final own = campaign.scoring.minOwnCampus;
    final other = campaign.scoring.minOtherCampus;
    final inRace = !campaign.outOfRace;
    final rule = own > 0 && other > 0
        ? l10n.raceRuleBoth(own, other)
        : own > 0
        ? l10n.raceRuleOwn(own)
        : l10n.raceRule(other);
    return Material(
      color: inRace ? Colors.transparent : const Color(0x14F59E0B),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CsSpace.md, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: inRace
                        ? const [Color(0xFF5EEAD4), Color(0xFF0F766E)]
                        : const [Color(0xFF818CF8), Color(0xFF3730A3)],
                  ),
                ),
                child: Icon(
                  inRace ? CsIcons.check : CsIcons.lock,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.raceTitle,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rule,
                      style: context.text.bodySmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (inRace)
                      Text(
                        l10n.raceDone,
                        style: context.text.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else ...[
                      if (own > 0)
                        _Steps(
                          have: campaign.myOwnCampus,
                          need: own,
                          label: l10n.raceOwnProgress(
                            campaign.myOwnCampus.clamp(0, own),
                            own,
                          ),
                        ),
                      if (own > 0 && other > 0) const SizedBox(height: 4),
                      if (other > 0)
                        _Steps(
                          have: campaign.myOtherCampus,
                          need: other,
                          label: l10n.raceOtherProgress(
                            campaign.myOtherCampus.clamp(0, other),
                            other,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (onTap != null && !inRace) ...[
                const SizedBox(width: CsSpace.xs),
                Icon(CsIcons.chevronRight, color: cs.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A dot per friend needed, filled for the ones I have, and [label]
/// ("Your university 1/3").
class _Steps extends StatelessWidget {
  const _Steps({required this.have, required this.need, required this.label});

  final int have;
  final int need;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Row(
      children: [
        for (var i = 0; i < need.clamp(0, 6); i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < have ? const Color(0xFFF59E0B) : cs.surfaceVariant,
              border: Border.all(
                color: i < have ? const Color(0xFFFDE68A) : cs.border,
              ),
            ),
          ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
