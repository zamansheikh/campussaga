import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../app/clock.dart';
import '../../app/di.dart';
import 'promo_slot.dart';
import 'promo_tracker.dart';

/// Student deals: offers the team picked, "Near you" (shown to my
/// university or city) first, then those for every student. A search box
/// once there are many. Expired ones never show.
class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  List<Promo>? _deals;
  Failure? _failure;
  final _hidden = <String>{};
  String _q = '';
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
    if (getIt.isRegistered<PromoTracker>()) {
      unawaited(getIt<PromoTracker>().flush());
    }
    try {
      final list = await getIt<SponsorsRepository>().promos(
        PromoPlacement.deals,
        lang: _lang ?? 'en',
      );
      if (mounted) {
        setState(() {
          _deals = list;
          _failure = null;
        });
      }
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    }
  }

  bool _matches(Promo p) {
    if (_q.isEmpty) return true;
    final q = _q.toLowerCase();
    return p.title.toLowerCase().contains(q) ||
        p.body.toLowerCase().contains(q) ||
        p.sponsor.name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final now = appNow();
    final deals = [
      for (final p in _deals ?? const <Promo>[])
        if (!_hidden.contains(p.id) &&
            (p.expiresAt == null || p.expiresAt!.isAfter(now)) &&
            _matches(p))
          p,
    ];
    bool near(Promo p) => p.targeted;
    final nearby = deals.where(near).toList();
    final everywhere = deals.where((p) => !near(p)).toList();
    Widget group(String title, List<Promo> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CsSectionTitle(title: title),
        for (final p in list)
          Padding(
            padding: const EdgeInsets.only(bottom: CsSpace.sm + 4),
            child: PromoView(
              key: ValueKey(p.id),
              promo: p,
              onHide: () => setState(() => _hidden.add(p.id)),
            ),
          ),
        const SizedBox(height: CsSpace.sm),
      ],
    );
    final Widget body;
    if (_deals == null && _failure == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_deals == null) {
      body = CsEmptyState(
        icon: CsIcons.offline,
        title: l10n.dealsEmpty,
        actionLabel: l10n.tryAgain,
        onAction: _load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.screen,
            CsSpace.sm,
            CsSpace.screen,
            CsSpace.xl,
          ),
          children: [
            Text(
              l10n.dealsHint,
              style: context.text.bodyMedium?.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: CsSpace.md),
            if ((_deals?.length ?? 0) > 6) ...[
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.dealsSearch,
                  prefixIcon: const Icon(CsIcons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
              const SizedBox(height: CsSpace.md),
            ],
            if (deals.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xl),
                child: CsEmptyState(
                  icon: CsIcons.deals,
                  title: l10n.dealsEmpty,
                ),
              ),
            if (nearby.isNotEmpty) group(l10n.dealsNearYou, nearby),
            if (everywhere.isNotEmpty)
              group(
                nearby.isEmpty ? l10n.dealsTitle : l10n.dealsEverywhere,
                everywhere,
              ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dealsTitle)),
      body: SafeArea(child: body),
    );
  }
}
