import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/di.dart';
import '../../app/env.dart';
import 'promo_tracker.dart';

/// An ad's picture or a sponsor's logo from its API path, or null.
ImageProvider? promoImage(String? path) => path == null || path.isEmpty
    ? null
    : NetworkImage('${Env.apiBaseUrl}$path');

PromoTracker? get _tracker =>
    getIt.isRegistered<PromoTracker>() ? getIt<PromoTracker>() : null;

/// Logs a view of [promo] for this screen [visit].
void logPromoView(Promo promo, Object visit) =>
    _tracker?.log(promo.id, PromoEventType.view, visit: visit);

/// Opens where [link] goes: a website in the in-app browser, or a screen.
Future<void> openPromoLink(BuildContext context, PromoLink link) async {
  if (!link.web) {
    unawaited(context.push(link.url));
    return;
  }
  final uri = Uri.tryParse(link.url);
  if (uri == null || uri.scheme != 'https') return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = AppLocalizations.of(context).openLinkFailed;
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok) ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    ok = false;
  }
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(failed)));
}

/// A tap on [promo]: counted, then its link (if any) opens.
Future<void> openPromo(BuildContext context, Promo promo) async {
  _tracker?.log(promo.id, PromoEventType.tap);
  final link = promo.link;
  if (link != null) await openPromoLink(context, link);
}

/// A deal's code copied: to the clipboard, counted, and said.
Future<void> copyPromoCode(BuildContext context, Promo promo) async {
  final code = promo.code;
  if (code == null) return;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: code));
  _tracker?.log(promo.id, PromoEventType.copy);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.dealCopied(code))));
}

/// "Why am I seeing this?": who it's shown to, that sponsors never see who
/// you are, that our team picks the ads, and "Hide this ad" (7 days).
/// [onHidden] removes it from the screen.
Future<void> showPromoWhy(
  BuildContext context,
  Promo promo, {
  required VoidCallback onHidden,
}) async {
  final hide = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cs = sheet.cs;
      final muted = sheet.text.bodyMedium?.copyWith(color: cs.textSecondary);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            0,
            CsSpace.lg,
            CsSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CsBrandLogo(
                    name: promo.sponsor.name,
                    logo: promoImage(promo.sponsor.logoUrl),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.promoWhyTitle, style: sheet.text.titleMedium),
                        Text(
                          '${l10n.promoSponsored} · ${promo.sponsor.name}',
                          style: sheet.text.bodySmall?.copyWith(
                            color: cs.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.md),
              if (promo.why.isNotEmpty) ...[
                Text(promo.why, style: sheet.text.bodyLarge),
                const SizedBox(height: CsSpace.sm),
              ],
              Text(l10n.promoWhyPrivacy, style: muted),
              const SizedBox(height: CsSpace.xs),
              Text(l10n.promoWhyCurated, style: muted),
              const SizedBox(height: CsSpace.lg),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(sheet).pop(true),
                icon: const Icon(CsIcons.hidden, size: 18),
                label: Text(l10n.promoHide),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (hide != true || !context.mounted) return;
  _tracker?.log(promo.id, PromoEventType.hide);
  onHidden();
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.promoHidden)));
}
