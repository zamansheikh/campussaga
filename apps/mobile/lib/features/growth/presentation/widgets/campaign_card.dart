import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import 'campaign_banner.dart';

/// On Today, while a prize campaign is live: its poster (banner photo or
/// the drawn prize visual) with the title, top prize and time left, then
/// my rank and Invite friends. Tap it for the campaign.
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
            ],
          ),
        ),
      ),
    );
  }
}
