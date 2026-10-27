import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';

/// Home screen. R1: next class with countdown, then the rest of today.
/// Until the student joins a class group it explains how that works.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  void _comingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.screen,
            CsSpace.lg,
            CsSpace.screen,
            CsSpace.xl,
          ),
          children: [
            const _Greeting(),
            const SizedBox(height: CsSpace.lg),
            _JoinCard(onJoin: () => _comingSoon(context)),
            const SizedBox(height: CsSpace.lg),
            CsSection(
              title: l10n.todayStepsTitle,
              children: [
                _Step(number: 1, text: l10n.todayStep1),
                _Step(number: 2, text: l10n.todayStep2),
                _Step(number: 3, text: l10n.todayStep3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.select((AuthBloc b) => b.state.user);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final name =
        (user?.displayName?.trim().split(RegExp(r'\s+')).first ?? '').isNotEmpty
        ? user!.displayName!.trim().split(RegExp(r'\s+')).first
        : (user?.email.split('@').first ?? '');
    final greeting = switch (now.hour) {
      < 12 => l10n.greetingMorning(name),
      < 17 => l10n.greetingAfternoon(name),
      _ => l10n.greetingEvening(name),
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.MMMMEEEEd(locale).format(now),
                style: context.text.labelLarge?.copyWith(
                  color: context.cs.primary,
                ),
              ),
              const SizedBox(height: CsSpace.xs),
              Text(greeting, style: context.text.headlineSmall),
            ],
          ),
        ),
        if (user != null) ...[
          const SizedBox(width: CsSpace.md),
          CsAvatar(name: user.displayName ?? user.email, size: 44),
        ],
      ],
    );
  }
}

/// Brand-coloured card: no classes yet, join your class group.
class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const onBrand = Colors.white;
    return Container(
      padding: const EdgeInsets.all(CsSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CsRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Large faint icon as a texture in the corner.
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 120,
              color: onBrand.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: onBrand.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(CsRadius.md),
                ),
                child: const Icon(Icons.groups_rounded, color: onBrand),
              ),
              const SizedBox(height: CsSpace.md),
              Text(
                l10n.todayEmptyTitle,
                style: context.text.titleLarge?.copyWith(color: onBrand),
              ),
              const SizedBox(height: CsSpace.xs),
              Text(
                l10n.todayEmptyMessage,
                style: context.text.bodyMedium?.copyWith(
                  color: onBrand.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: CsSpace.lg),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: onBrand,
                  foregroundColor: const Color(0xFF0F766E),
                  minimumSize: const Size(0, 48),
                ),
                onPressed: onJoin,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.joinClassGroup),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final digits = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(number);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.md, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              digits,
              style: context.text.labelLarge?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: context.text.bodyLarge)),
        ],
      ),
    );
  }
}
