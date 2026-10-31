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

/// On Today, while a prize campaign is live: its title, top prize, the time
/// left, my rank and score, and Invite friends. Tap it for the campaign.
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
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final prize = c.topPrize;
    final left = c.endsAt == null
        ? null
        : timeLeftText(l10n, c.endsAt!, appNow());
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.md),
      child: Material(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(CsRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(c),
          child: Padding(
            padding: const EdgeInsets.all(CsSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CsIcons.trophy, color: cs.primary),
                    ),
                    const SizedBox(width: CsSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          if (prize != null)
                            Text(
                              l10n.campaignTopPrize(prize.title),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(CsIcons.chevronRight, color: cs.onPrimaryContainer),
                  ],
                ),
                const SizedBox(height: CsSpace.md),
                Wrap(
                  spacing: CsSpace.sm,
                  runSpacing: CsSpace.sm,
                  children: [
                    if (left != null) CsPill(icon: CsIcons.timer, label: left),
                    CsPill(
                      icon: CsIcons.rankings,
                      label: campaignStanding(l10n, c),
                    ),
                  ],
                ),
                const SizedBox(height: CsSpace.md),
                FilledButton.icon(
                  onPressed: () => shareMyInvite(context),
                  icon: const Icon(CsIcons.invite),
                  label: Text(l10n.inviteFriendsTitle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
