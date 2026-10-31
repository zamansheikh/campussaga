import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di.dart';
import '../../../../app/env.dart';
import '../../../../app/router.dart';
import '../growth_text.dart';
import '../widgets/campaign_banner.dart';
import '../widgets/prize_claim_card.dart';

/// One prize campaign: prizes, the leaderboard (Bangladesh or my
/// university, my own row pinned), how invites count, the rules, and, for a
/// winner, the claim form.
class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key, required this.campaignId});

  final String campaignId;

  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  Campaign? _campaign;
  Failure? _failure;
  Leaderboard? _board;
  Failure? _boardFailure;
  var _scope = LeaderboardScope.all;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final lang = Localizations.localeOf(context).languageCode;
    final repo = getIt<GrowthRepository>();
    try {
      final c = await repo.campaign(widget.campaignId, lang: lang);
      if (mounted) {
        setState(() {
          _campaign = c;
          _failure = null;
        });
      }
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
      return;
    }
    await _loadBoard();
  }

  Future<void> _loadBoard() async {
    final scope = _scope;
    try {
      final b = await getIt<GrowthRepository>().leaderboard(
        widget.campaignId,
        scope,
      );
      if (mounted && scope == _scope) {
        setState(() {
          _board = b;
          _boardFailure = null;
        });
      }
    } on Failure catch (f) {
      if (mounted && scope == _scope) setState(() => _boardFailure = f);
    }
  }

  void _pick(LeaderboardScope scope) {
    if (scope == _scope) return;
    setState(() {
      _scope = scope;
      _board = null;
      _boardFailure = null;
    });
    unawaited(_loadBoard());
  }

  Future<void> _rules(Campaign c) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final url = c.rulesUrl.isNotEmpty
        ? c.rulesUrl
        : '${Env.siteUrl}/campaigns/${c.id}';
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.openLinkFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _campaign;
    final failure = _failure;
    final me = _board?.me;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.title ?? l10n.campaignsTitle),
        actions: [
          if (c != null)
            CsBarButton(label: l10n.campaignRules, onPressed: () => _rules(c)),
        ],
      ),
      body: SafeArea(
        child: c != null
            ? RefreshIndicator(onRefresh: _load, child: _content(context, c))
            : failure != null
            ? CsEmptyState(
                icon: CsIcons.offline,
                title: failure is NotFoundFailure
                    ? l10n.campaignNotFound
                    : growthErrorText(l10n, failure),
                actionLabel: failure is NotFoundFailure ? null : l10n.tryAgain,
                onAction: failure is NotFoundFailure
                    ? null
                    : () {
                        setState(() => _failure = null);
                        unawaited(_load());
                      },
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: me == null
          ? null
          : Material(
              color: context.cs.surface,
              elevation: 8,
              child: SafeArea(
                child: _BoardRow(row: me, pinned: true, onOpen: _openRow),
              ),
            ),
    );
  }

  void _openRow(LeaderboardRow row) {
    final id = row.userId;
    if (id != null) unawaited(context.push(Routes.student(id)));
  }

  Widget _content(BuildContext context, Campaign c) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final board = _board;
    final muted = context.text.bodyMedium?.copyWith(color: cs.textSecondary);
    return CsPage(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampaignBanner(campaign: c, height: 176),
              Padding(
                padding: const EdgeInsets.all(CsSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.body.isNotEmpty) ...[
                      Text(c.body, style: context.text.bodyMedium),
                      const SizedBox(height: CsSpace.md),
                    ],
                    CampaignStandingRow(campaign: c),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (c.won case final win?) ...[
          const SizedBox(height: CsSpace.lg),
          PrizeClaimCard(campaignId: c.id, win: win),
        ],
        if (c.prizes.isNotEmpty) ...[
          const SizedBox(height: CsSpace.lg),
          CsSection(
            title: l10n.campaignPrizes,
            children: [
              for (final p in c.prizes)
                CsRow(
                  icon: CsIcons.gift,
                  title: p.title,
                  value: prizeRankText(l10n, p),
                  showChevron: false,
                ),
            ],
          ),
        ],
        const SizedBox(height: CsSpace.lg),
        CsSectionTitle(title: l10n.campaignLeaderboard),
        Wrap(
          spacing: CsSpace.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.campaignScopeAll),
              selected: _scope == LeaderboardScope.all,
              onSelected: (_) => _pick(LeaderboardScope.all),
            ),
            ChoiceChip(
              label: Text(l10n.campaignScopeUniversity),
              selected: _scope == LeaderboardScope.university,
              onSelected: (_) => _pick(LeaderboardScope.university),
            ),
          ],
        ),
        const SizedBox(height: CsSpace.md),
        if (_boardFailure != null)
          CsEmptyState(
            icon: CsIcons.offline,
            title: growthErrorText(l10n, _boardFailure!),
            actionLabel: l10n.tryAgain,
            onAction: () {
              setState(() => _boardFailure = null);
              unawaited(_loadBoard());
            },
          )
        else if (board == null)
          const Padding(
            padding: EdgeInsets.all(CsSpace.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (board.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(CsSpace.xs),
            child: Text(l10n.campaignLeaderboardEmpty, style: muted),
          )
        else
          Material(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CsRadius.lg),
              side: BorderSide(color: cs.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < board.rows.length; i++) ...[
                  if (i > 0) const Divider(),
                  _BoardRow(row: board.rows[i], onOpen: _openRow),
                ],
              ],
            ),
          ),
        const SizedBox(height: CsSpace.lg),
        CsSection(
          title: l10n.campaignHowTitle,
          children: [
            Padding(
              padding: const EdgeInsets.all(CsSpace.md),
              child: Text(
                l10n.inviteCountsRule,
                style: context.text.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One leaderboard line: rank, name with the badge shown by it, university
/// and score. Opens the profile unless the student hides their name.
class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.row,
    required this.onOpen,
    this.pinned = false,
  });

  final LeaderboardRow row;
  final ValueChanged<LeaderboardRow> onOpen;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final badge = row.featuredBadge;
    final name = row.me && row.name.isEmpty ? l10n.youLabel : row.name;
    return InkWell(
      onTap: row.userId == null ? null : () => onOpen(row),
      child: Container(
        color: row.me ? cs.primaryContainer.withValues(alpha: 0.5) : null,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(
          horizontal: CsSpace.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${row.rank}',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: row.rank <= 3 ? cs.primary : cs.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                // The pinned row sits in a bar with bounded height.
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: row.me ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                      if (row.me) ...[
                        const SizedBox(width: CsSpace.xs),
                        CsBadge(
                          label: l10n.youLabel,
                          tone: CsBadgeTone.neutral,
                        ),
                      ],
                      if (badge != null) ...[
                        const SizedBox(width: CsSpace.xs),
                        CsBadgeIcon(
                          badgeKey: badge.key,
                          tier: badge.tier,
                          size: 20,
                          semanticLabel: badgeName(l10n, badge.key),
                        ),
                      ],
                    ],
                  ),
                  if (row.university.isNotEmpty)
                    Text(
                      row.university,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: CsSpace.sm),
            Text(
              l10n.campaignScore(row.score),
              style: context.text.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
