import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di.dart';
import '../../../app/env.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../classes/data/invite_link.dart';
import 'growth_text.dart';
import 'invite_share.dart';

/// Hands an image and text to the phone's share sheet. A variable so tests
/// can see what would be shared.
Future<void> Function(List<int> png, String text, Rect? origin) cardShare =
    (png, text, origin) async {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(png),
              mimeType: 'image/png',
              name: 'varsitykotha.png',
            ),
          ],
          text: text,
          sharePositionOrigin: origin,
        ),
      );
    };

String _linkOf(ReferralStats s) =>
    s.link.isNotEmpty ? s.link : InviteLink.personalLink(s.code).toString();

Future<ReferralStats?> _stats(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    return await getIt<GrowthRepository>().referrals();
  } on Failure catch (f) {
    messenger.showSnackBar(SnackBar(content: Text(growthErrorText(l10n, f))));
    return null;
  }
}

/// My invite link as a big QR code that classmates scan in class, with my
/// name and a Share button.
Future<void> showInviteQr(BuildContext context, {ReferralStats? stats}) async {
  final s = stats ?? await _stats(context);
  if (s == null || !context.mounted) return;
  final user = context.read<AuthBloc>().state.user;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cs = sheet.cs;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            0,
            CsSpace.lg,
            CsSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.inviteQrTitle, style: sheet.text.titleLarge),
              const SizedBox(height: CsSpace.md),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(CsRadius.lg),
                ),
                child: QrImageView(
                  data: _linkOf(s),
                  size: 220,
                  backgroundColor: Colors.white,
                  semanticsLabel: l10n.inviteQrTitle,
                ),
              ),
              const SizedBox(height: CsSpace.md),
              if (user?.displayName case final name? when name.isNotEmpty)
                Text(name, style: sheet.text.titleMedium),
              if (user?.university case final u?)
                Text(
                  u.name,
                  textAlign: TextAlign.center,
                  style: sheet.text.bodySmall?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
              const SizedBox(height: CsSpace.sm),
              Text(
                l10n.inviteQrHint,
                textAlign: TextAlign.center,
                style: sheet.text.bodySmall?.copyWith(color: cs.textSecondary),
              ),
              const SizedBox(height: CsSpace.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => shareMyInvite(sheet, stats: s),
                  icon: const Icon(CsIcons.share, size: 18),
                  label: Text(l10n.campusShare),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A story-size card of my place in [campaign] (rank and points, or that
/// I'm in the race), my badge, and a QR of my invite link: shown first,
/// then shared as an image with my link in the text.
Future<void> showShareCard(BuildContext context, Campaign campaign) async {
  final s = await _stats(context);
  if (s == null || !context.mounted) return;
  final user = context.read<AuthBloc>().state.user;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShareCardSheet(campaign: campaign, stats: s, user: user),
  );
}

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet({
    required this.campaign,
    required this.stats,
    required this.user,
  });

  final Campaign campaign;
  final ReferralStats stats;
  final UserProfile? user;

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<void> _share(Rect? origin) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // 270 × 480 on screen; 4× is 1080 × 1920, a story.
      final image = await boundary.toImage(pixelRatio: 4);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;
      await cardShare(
        bytes.buffer.asUint8List(),
        inviteMessage(l10n, widget.stats),
        origin,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.lg,
          0,
          CsSpace.lg,
          CsSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _card,
              child: _StoryCard(
                campaign: widget.campaign,
                link: _linkOf(widget.stats),
                user: widget.user,
              ),
            ),
            const SizedBox(height: CsSpace.md),
            Builder(
              builder: (button) => SizedBox(
                width: 270,
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          final box = button.findRenderObject() as RenderBox?;
                          unawaited(
                            _share(
                              box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            ),
                          );
                        },
                  icon: const Icon(CsIcons.share, size: 18),
                  label: Text(l10n.campusShare),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card itself, 270 × 480: the campaign poster, me (badge, name,
/// university), my place, and a QR of my invite link.
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.campaign,
    required this.link,
    required this.user,
  });

  final Campaign campaign;
  final String link;
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = campaign;
    final prize = c.topPrize;
    final banner = c.bannerUrl;
    final name = user?.displayName ?? '';
    final badge = user?.featuredBadge;
    final status = c.myRank != null
        ? l10n.campaignMyRank(c.myRank!, l10n.campaignScore(c.myScore))
        : c.outOfRace
        ? l10n.campaignScore(c.myScore)
        : l10n.shareCardInRace;
    const white = Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 270,
        height: 480,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3B39), Color(0xFF141A46), Color(0xFF0B1220)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CsPrizeBanner(
              title: c.title,
              prize: prize == null ? null : l10n.campaignTopPrize(prize.title),
              tag: l10n.appName,
              height: 156,
              image: banner == null || banner.isEmpty
                  ? null
                  : NetworkImage('${Env.apiBaseUrl}$banner'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  if (badge != null)
                    CsBadgeIcon(badgeKey: badge.key, tier: badge.tier, size: 52)
                  else
                    CsAvatar(name: name.isEmpty ? '?' : name, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium?.copyWith(
                            color: white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (user?.university case final u?)
                          Text(
                            u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: white.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: FittedBox(
                // One line, whatever the language.
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  status,
                  maxLines: 1,
                  style: context.text.titleLarge?.copyWith(
                    color: const Color(0xFFFBBF24),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.shareCardPitch,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  color: white.withValues(alpha: 0.85),
                  height: 1.3,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  QrImageView(
                    data: link,
                    size: 84,
                    padding: EdgeInsets.zero,
                    backgroundColor: white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.shareCardScan,
                          style: context.text.titleSmall?.copyWith(
                            color: const Color(0xFF0B1220),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.shareCardJoin,
                          style: context.text.bodySmall?.copyWith(
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          link.replaceFirst(RegExp('^https?://'), ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall?.copyWith(
                            color: const Color(0xFF0F766E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
