import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/clock.dart';
import '../../../../app/env.dart';
import '../growth_text.dart';
import '../invite_share.dart';

/// A campaign's poster: the team's banner photo when there is one, else
/// the drawn prize visual; the title, the top prize, and "LIVE · 4d left"
/// (or ended/announced) on top.
class CampaignBanner extends StatelessWidget {
  const CampaignBanner({super.key, required this.campaign, this.height = 150});

  final Campaign campaign;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = campaign;
    final now = appNow();
    final prize = c.topPrize;
    final left = c.endsAt == null ? null : timeLeftText(l10n, c.endsAt!, now);
    final tag = c.isLive(now)
        ? [l10n.busLive.toUpperCase(), ?left].join(' · ')
        : c.status == CampaignStatus.announced
        ? l10n.campaignAnnounced
        : l10n.campaignEnded;
    final banner = c.bannerUrl;
    return CsPrizeBanner(
      title: c.title,
      prize: prize == null ? null : l10n.campaignTopPrize(prize.title),
      tag: tag,
      height: height,
      image: banner == null || banner.isEmpty
          ? null
          : NetworkImage('${Env.apiBaseUrl}$banner'),
    );
  }
}

/// Under the banner: my standing ("Rank 12 · 4 invites") and, while the
/// campaign is live, a small Invite friends button, in one row.
class CampaignStandingRow extends StatelessWidget {
  const CampaignStandingRow({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Row(
      children: [
        Icon(CsIcons.rankings, size: 18, color: cs.primary),
        const SizedBox(width: CsSpace.sm),
        Expanded(
          child: Text(
            campaignStanding(l10n, campaign),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall,
          ),
        ),
        if (campaign.isLive(appNow())) ...[
          const SizedBox(width: CsSpace.sm),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => shareMyInvite(context),
            icon: const Icon(CsIcons.invite, size: 18),
            label: Text(l10n.inviteFriendsTitle),
          ),
        ],
      ],
    );
  }
}
