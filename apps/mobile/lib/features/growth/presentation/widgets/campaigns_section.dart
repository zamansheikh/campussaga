import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../growth_text.dart';

/// On Profile: live and recently announced prize campaigns, one row each.
/// Nothing shows when there are none (or when it can't load).
class CampaignsSection extends StatefulWidget {
  const CampaignsSection({super.key});

  @override
  State<CampaignsSection> createState() => _CampaignsSectionState();
}

class _CampaignsSectionState extends State<CampaignsSection> {
  List<Campaign> _list = const [];
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
      if (mounted) setState(() => _list = list);
    } on Failure {
      // Only an extra: say nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final c in _list)
        if (c.status == CampaignStatus.live ||
            c.status == CampaignStatus.announced ||
            c.status == CampaignStatus.ended)
          c,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final now = appNow();
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.lg),
      child: CsSection(
        title: l10n.campaignsTitle,
        children: [
          for (final c in shown)
            CsRow(
              icon: CsIcons.trophy,
              title: c.title,
              subtitle: switch (c.status) {
                CampaignStatus.live when c.isLive(now) => [
                  l10n.campaignLive,
                  if (c.endsAt != null) ?timeLeftText(l10n, c.endsAt!, now),
                ].join(' · '),
                CampaignStatus.announced => l10n.campaignAnnounced,
                _ => l10n.campaignEnded,
              },
              onTap: () => context.push(Routes.campaign(c.id)),
            ),
        ],
      ),
    );
  }
}
