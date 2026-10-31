import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../app/di.dart';
import 'promo_actions.dart';
import 'promo_tracker.dart';

/// One ad place on a screen (Today, the bottom of a page). It asks the
/// server for this [placement], waits for the picture, then fades in; it
/// counts a view once half of it has been on screen for a second; "Hide
/// this ad" folds it away. Nothing shows while loading, offline or when
/// there's no ad.
class PromoSlot extends StatefulWidget {
  const PromoSlot({
    super.key,
    required this.placement,
    this.padding = EdgeInsets.zero,
  });

  /// A `PromoPlacement`.
  final String placement;

  /// Around the ad, only when there is one.
  final EdgeInsets padding;

  @override
  State<PromoSlot> createState() => _PromoSlotState();
}

class _PromoSlotState extends State<PromoSlot> {
  Promo? _promo;
  bool _hidden = false;
  String? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _lang) {
      _lang = lang;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<SponsorsRepository>()) return;
    final tracker = getIt.isRegistered<PromoTracker>()
        ? getIt<PromoTracker>()
        : null;
    unawaited(tracker?.flush());
    try {
      final list = await getIt<SponsorsRepository>().promos(
        widget.placement,
        lang: _lang ?? 'en',
      );
      if (list.isEmpty || !mounted) return;
      final promo = list.first;
      // Show it only once its picture is ready, so it appears whole.
      final image = promoImage(promo.imageUrl);
      if (image != null) {
        var failed = false;
        await precacheImage(image, context, onError: (_, _) => failed = true);
        if (failed && promo.kind != PromoKind.line) return;
      }
      if (mounted) setState(() => _promo = promo);
    } on Failure {
      // Ads are extras: say nothing.
    }
  }

  void _hide() => setState(() => _hidden = true);

  @override
  Widget build(BuildContext context) {
    final p = _promo;
    final show = p != null && !_hidden;
    return AnimatedSize(
      duration: CsMotion.normal,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !show
          ? const SizedBox(width: double.infinity)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: CsMotion.normal,
              curve: Curves.easeOut,
              builder: (context, t, child) => Opacity(opacity: t, child: child),
              child: Padding(
                padding: widget.padding,
                child: PromoView(promo: p, onHide: _hide),
              ),
            ),
    );
  }
}

/// [promo] drawn for its kind, counting its views; [onHide] removes it.
class PromoView extends StatefulWidget {
  const PromoView({super.key, required this.promo, required this.onHide});

  final Promo promo;
  final VoidCallback onHide;

  @override
  State<PromoView> createState() => _PromoViewState();
}

class _PromoViewState extends State<PromoView> {
  Timer? _dwell;

  /// This screen visit, so a view counts once per visit.
  final _visit = Object();

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  void _visible(VisibilityInfo info) {
    if (!mounted) return;
    if (info.visibleFraction >= 0.5) {
      _dwell ??= Timer(const Duration(seconds: 1), () {
        if (mounted) logPromoView(widget.promo, _visit);
      });
    } else {
      _dwell?.cancel();
      _dwell = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = widget.promo;
    void why() => showPromoWhy(context, p, onHidden: widget.onHide);
    final tap = p.link == null ? null : () => openPromo(context, p);
    final Widget child = switch (p.kind) {
      PromoKind.line || PromoKind.campaign => CsSponsorLine(
        label: p.title.isNotEmpty ? p.title : l10n.promoSupportedBy,
        brand: p.sponsor.name,
        logo: promoImage(p.sponsor.logoUrl),
        onTap: tap,
        onLongPress: why,
      ),
      PromoKind.feed => CsPromoFeedPost(
        sponsoredLabel: l10n.promoSponsored,
        brand: p.sponsor.name,
        title: p.title,
        body: p.body,
        cta: p.cta,
        logo: promoImage(p.sponsor.logoUrl),
        image: promoImage(p.imageUrl),
        onTap: tap,
        onInfo: why,
        infoLabel: l10n.promoWhyTitle,
      ),
      PromoKind.deal => PromoDeal(promo: p, onHide: widget.onHide),
      PromoKind.card => CsPromoCard(
        sponsoredLabel: l10n.promoSponsored,
        brand: p.sponsor.name,
        title: p.title,
        body: p.body,
        cta: p.cta,
        image: promoImage(p.imageUrl),
        onTap: tap,
        onInfo: why,
        infoLabel: l10n.promoWhyTitle,
      ),
    };
    return VisibilityDetector(
      key: ValueKey('promo-${p.id}-${identityHashCode(_visit)}'),
      onVisibilityChanged: _visible,
      child: child,
    );
  }
}

/// A deal as a card: code with Copy, last day, terms, Visit.
class PromoDeal extends StatelessWidget {
  const PromoDeal({super.key, required this.promo, required this.onHide});

  final Promo promo;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = promo;
    final until = p.expiresAt;
    return CsDealCard(
      brand: p.sponsor.name,
      title: p.title,
      body: p.body,
      sponsoredLabel: l10n.promoSponsored,
      logo: promoImage(p.sponsor.logoUrl) ?? promoImage(p.imageUrl),
      code: p.code,
      copyLabel: l10n.dealCopy,
      onCopy: () => copyPromoCode(context, p),
      until: until == null
          ? null
          : l10n.dealUntil(
              MaterialLocalizations.of(context).formatMediumDate(until),
            ),
      terms: p.terms,
      termsLabel: l10n.dealTerms,
      visitLabel: p.cta.isNotEmpty ? p.cta : l10n.dealVisit,
      onVisit: p.link == null ? null : () => openPromo(context, p),
      onInfo: () => showPromoWhy(context, p, onHidden: onHide),
      infoLabel: l10n.promoWhyTitle,
    );
  }
}
