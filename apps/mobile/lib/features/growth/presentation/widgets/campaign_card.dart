import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import 'campaign_banner.dart';
import 'missions_section.dart';

/// On Today, while a prize campaign is live: its poster (banner photo or
/// the drawn prize visual) with the title, top prize and time left, then
/// my rank and Invite friends, and the next way to earn points. Tap it for
/// the campaign.
/// Nothing shows without a live campaign (or when it can't load).
class CampaignCard extends StatefulWidget {
  const CampaignCard({super.key});

  @override
  State<CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<CampaignCard> {
  Campaign? _live;
  String? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _lang) {
      _lang = lang;
      _load();
    }
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<GrowthRepository>()) return;
    try {
      final list = await getIt<GrowthRepository>().campaigns(lang: _lang!);
      final now = appNow();
      final live = [
        for (final c in list)
          if (c.isLive(now)) c,
      ]..sort((a, b) => (a.endsAt ?? now).compareTo(b.endsAt ?? now));
      if (mounted) setState(() => _live = live.isEmpty ? null : live.first);
      if (live.isEmpty) return;
      // The detail has my progress on each way to earn (for "Next: …").
      final detail = await getIt<GrowthRepository>().campaign(
        live.first.id,
        lang: _lang!,
      );
      if (mounted) setState(() => _live = detail);
    } on Failure {
      // Only a nudge: say nothing.
    }
  }

  Future<void> _open(Campaign c) async {
    await context.push(Routes.campaign(c.id));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _live;
    if (c == null) return const SizedBox.shrink();
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.md),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.lg),
          side: BorderSide(color: cs.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampaignBanner(campaign: c, height: 140),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: CampaignStandingRow(campaign: c),
              ),
              if (nextMission(c) case final m?) ...[
                Divider(height: 1, color: cs.border),
                _NextMission(campaign: c, mission: m),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Next: Join your section · +2", opening where it's done.
class _NextMission extends StatelessWidget {
  const _NextMission({required this.campaign, required this.mission});

  final Campaign campaign;
  final CampaignMission mission;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return InkWell(
      onTap: () => openMission(context, campaign, mission),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            const Icon(CsIcons.sparkle, size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: CsSpace.sm),
            Expanded(
              child: Text(
                l10n.campaignNext(
                  missionTitle(l10n, mission.key),
                  mission.points,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(CsIcons.chevronRight, size: 20, color: cs.textSecondary),
          ],
        ),
      ),
    );
  }
}
