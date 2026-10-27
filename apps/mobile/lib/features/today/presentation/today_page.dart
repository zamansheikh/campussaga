import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/clock.dart';
import '../../../app/router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../classes/presentation/bloc/my_classes_cubit.dart';
import '../../classes/presentation/class_format.dart';
import '../../classes/presentation/widgets/class_tile.dart';

/// Home screen: the next class with a countdown, then the rest of today.
/// Before the student joins a class group it explains how that works.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  // Keeps "in 25 min" and the next class current.
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 30),
    (_) => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    _tick;
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final classes = context.watch<MyClassesCubit>().state;
    final now = appNow();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: context.read<MyClassesCubit>().refresh,
          child: CsPage(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.screen,
              CsSpace.lg,
              CsSpace.screen,
              CsSpace.xl,
            ),
            children: [
              _Greeting(now: now),
              const SizedBox(height: CsSpace.lg),
              if (classes.failure is NetworkFailure && classes.hasGroups) ...[
                const _OfflineNotice(),
                const SizedBox(height: CsSpace.md),
              ],
              if (!classes.loaded)
                const Padding(
                  padding: EdgeInsets.all(CsSpace.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!classes.hasGroups) ...[
                const _JoinCard(),
                const SizedBox(height: CsSpace.lg),
                CsSection(
                  title: l10n.todayStepsTitle,
                  children: [
                    _Step(number: 1, text: l10n.todayStep1),
                    _Step(number: 2, text: l10n.todayStep2),
                    _Step(number: 3, text: l10n.todayStep3),
                  ],
                ),
              ] else
                ..._schedule(context, classes.groups, now),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _schedule(
    BuildContext context,
    List<ClassGroup> groups,
    DateTime now,
  ) {
    final l10n = AppLocalizations.of(context);
    final today = classesOn(groups, now);
    final current = today.where(
      (c) => !c.startsAt.isAfter(now) && c.endsAt.isAfter(now),
    );
    final upcoming = today.where((c) => c.startsAt.isAfter(now));
    final many = groups.length > 1;

    final Widget hero;
    if (current.isNotEmpty) {
      final c = current.first;
      hero = _HeroCard(
        badge: l10n.nowInClass,
        timing: l10n.endsInMinutes(_minutes(c.endsAt.difference(now))),
        item: c,
      );
    } else if (upcoming.isNotEmpty) {
      final c = upcoming.first;
      hero = _HeroCard(
        badge: l10n.nextClass,
        timing: _startsIn(l10n, c.startsAt.difference(now)),
        item: c,
      );
    } else {
      hero = _NothingLeft(
        groups: groups,
        title: today.isEmpty ? l10n.noClassesToday : l10n.doneForToday,
        now: now,
      );
    }

    return [
      hero,
      if (today.isNotEmpty) ...[
        const SizedBox(height: CsSpace.lg),
        CsSection(
          title: l10n.todaysClasses,
          children: [
            for (final c in today)
              ClassTile(
                slot: c.slot,
                groupTitle: many ? c.group.title : null,
                state: !c.endsAt.isAfter(now)
                    ? ClassTileState.past
                    : !c.startsAt.isAfter(now)
                    ? ClassTileState.now
                    : ClassTileState.normal,
                onTap: () => context.push(Routes.group(c.group.id)),
              ),
          ],
        ),
      ],
    ];
  }

  /// Whole minutes, rounded up ("in 1 min" until it starts).
  static int _minutes(Duration d) =>
      d.inMinutes + (d.inSeconds % 60 > 0 ? 1 : 0);

  static String _startsIn(AppLocalizations l10n, Duration d) {
    final m = _minutes(d);
    return m < 60
        ? l10n.startsInMinutes(m)
        : l10n.startsInHours(m ~/ 60, m % 60);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.select((AuthBloc b) => b.state.user);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = user?.displayName?.trim().split(RegExp(r'\s+')).first ?? '';
    final name = first.isNotEmpty
        ? first
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
          GestureDetector(
            onTap: () => context.go(Routes.profile),
            child: CsAvatar(name: user.displayName ?? user.email, size: 44),
          ),
        ],
      ],
    );
  }
}

/// The brand-coloured card used for the next class and the join prompt.
class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.child, this.icon});

  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
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
          if (icon != null)
            Positioned(
              right: -18,
              top: -18,
              child: Icon(
                icon,
                size: 120,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.badge,
    required this.timing,
    required this.item,
  });

  final String badge;
  final String timing;
  final ClassOnDay item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const white = Colors.white;
    final s = item.slot;
    final soft = context.text.bodyMedium?.copyWith(
      color: white.withValues(alpha: 0.85),
    );
    return GestureDetector(
      onTap: () => context.push(Routes.group(item.group.id)),
      child: _BrandCard(
        icon: Icons.schedule_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(CsRadius.full),
                  ),
                  child: Text(
                    badge,
                    style: context.text.labelMedium?.copyWith(
                      color: white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                Flexible(
                  child: Text(
                    timing,
                    style: context.text.labelLarge?.copyWith(color: white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            Text(
              s.courseCode,
              style: context.text.headlineSmall?.copyWith(color: white),
            ),
            if (s.courseTitle.isNotEmpty) Text(s.courseTitle, style: soft),
            const SizedBox(height: CsSpace.md),
            Wrap(
              spacing: CsSpace.md,
              runSpacing: CsSpace.xs,
              children: [
                _Meta(
                  icon: Icons.access_time_rounded,
                  text: rangeText(context, s),
                ),
                if (s.room.isNotEmpty)
                  _Meta(
                    icon: Icons.meeting_room_outlined,
                    text: l10n.roomShort(s.room),
                  ),
                if (s.teacher.isNotEmpty)
                  _Meta(icon: Icons.person_outline_rounded, text: s.teacher),
                if (s.kind == ClassKind.lab)
                  _Meta(icon: Icons.science_outlined, text: l10n.classLab),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Colors.white.withValues(alpha: 0.9);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Text(text, style: context.text.bodyMedium?.copyWith(color: c)),
      ],
    );
  }
}

/// No class left today: say so, and show when the next one is.
class _NothingLeft extends StatelessWidget {
  const _NothingLeft({
    required this.groups,
    required this.title,
    required this.now,
  });

  final List<ClassGroup> groups;
  final String title;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    ClassOnDay? next;
    for (var i = 1; i <= 7 && next == null; i++) {
      final list = classesOn(groups, now.add(Duration(days: i)));
      if (list.isNotEmpty) next = list.first;
    }
    final crGroup = groups.where((g) => g.isCr && g.slots.isEmpty).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CsSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(CsRadius.md),
              ),
              child: Icon(
                Icons.free_breakfast_outlined,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: CsSpace.md),
            Text(title, style: context.text.titleLarge),
            if (next != null) ...[
              const SizedBox(height: CsSpace.xs),
              Text(
                l10n.nextOn(weekdayName(context, next.date.weekday)),
                style: context.text.bodyMedium?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
              const SizedBox(height: CsSpace.md),
              CsSection(
                children: [
                  ClassTile(
                    slot: next.slot,
                    groupTitle: groups.length > 1 ? next.group.title : null,
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: CsSpace.xs),
              Text(
                crGroup != null ? l10n.noClassesYetCr : l10n.noClassesYetMember,
                style: context.text.bodyMedium?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
              if (crGroup != null) ...[
                const SizedBox(height: CsSpace.md),
                FilledButton.icon(
                  onPressed: () => context.push(Routes.newSlot(crGroup.id)),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addClass),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Brand card: no classes yet, join your class group (or create one).
class _JoinCard extends StatelessWidget {
  const _JoinCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const white = Colors.white;
    return _BrandCard(
      icon: Icons.calendar_month_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(CsRadius.md),
            ),
            child: const Icon(Icons.groups_rounded, color: white),
          ),
          const SizedBox(height: CsSpace.md),
          Text(
            l10n.todayEmptyTitle,
            style: context.text.titleLarge?.copyWith(color: white),
          ),
          const SizedBox(height: CsSpace.xs),
          Text(
            l10n.todayEmptyMessage,
            style: context.text.bodyMedium?.copyWith(
              color: white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: white,
              foregroundColor: const Color(0xFF0F766E),
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => context.push(Routes.joinGroup),
            icon: const Icon(Icons.vpn_key_outlined),
            label: Text(l10n.joinWithCode),
          ),
          const SizedBox(height: CsSpace.xs),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: white),
            onPressed: () => context.push(Routes.newGroup),
            child: Text(l10n.imTheCr),
          ),
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(CsRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: cs.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).offlineNotice,
              style: context.text.bodySmall,
            ),
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
