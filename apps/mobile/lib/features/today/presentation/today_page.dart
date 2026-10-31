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
import '../../announcements/presentation/announcement_widgets.dart';
import '../../announcements/presentation/seen_cubit.dart';
import '../../assessments/presentation/assessment_widgets.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../classes/presentation/bloc/my_classes_cubit.dart';
import '../../classes/presentation/class_format.dart';
import '../../classes/presentation/widgets/class_sheet.dart';
import '../../classes/presentation/widgets/class_tile.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../reminders/presentation/bloc/reminders_cubit.dart';
import '../../reminders/presentation/reminder_prompt.dart';

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
              else if (!classes.hasGroups && classes.personal.isEmpty) ...[
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
                ..._schedule(context, classes.routine, now),
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
    final happening = today.where((c) => !c.off);
    final current = happening.where(
      (c) => !c.startsAt.isAfter(now) && c.endsAt.isAfter(now),
    );
    final upcoming = happening.where((c) => c.startsAt.isAfter(now));
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
        title: happening.isEmpty ? l10n.noClassesToday : l10n.doneForToday,
        now: now,
      );
    }

    final reminders = context.watch<RemindersCubit>().state;
    final ask =
        reminders.loaded &&
        !reminders.settings.asked &&
        !reminders.settings.enabled &&
        groups.any((g) => g.slots.isNotEmpty);
    return [
      hero,
      if (ask) ...[const SizedBox(height: CsSpace.md), const ReminderPrompt()],
      _RecentAnnouncements(
        groups: groups.where((g) => !g.isPersonal).toList(),
        now: now,
      ),
      ComingUpSection(groups: groups, now: now),
      if (today.isNotEmpty) ...[
        const SizedBox(height: CsSpace.lg),
        CsSection(
          title: l10n.todaysClasses,
          children: [
            for (final c in today)
              ClassTile.on(
                c,
                groupTitle: many ? groupLabel(context, c.group) : null,
                state: !c.endsAt.isAfter(now)
                    ? ClassTileState.past
                    : !c.startsAt.isAfter(now)
                    ? ClassTileState.now
                    : ClassTileState.normal,
                onTap: () => showClassSheet(context, c),
              ),
          ],
        ),
      ],
      const SizedBox(height: CsSpace.lg),
      _MyGroups(groups: groups.where((g) => !g.isPersonal).toList()),
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

/// Pinned and last-3-days announcements from all groups, newest first.
class _RecentAnnouncements extends StatelessWidget {
  const _RecentAnnouncements({required this.groups, required this.now});

  final List<ClassGroup> groups;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seen = context.watch<SeenCubit>();
    final recent = [
      for (final g in groups)
        for (final a in g.announcements)
          if (a.pinned || now.difference(a.createdAt).inDays < 3) (g, a),
    ]..sort((x, y) => y.$2.createdAt.compareTo(x.$2.createdAt));
    if (recent.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: CsSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.xs,
              0,
              CsSpace.xs,
              CsSpace.sm,
            ),
            child: Text(
              l10n.announcements.toUpperCase(),
              style: context.text.labelMedium?.copyWith(
                letterSpacing: 0.8,
                color: context.cs.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final (g, a) in recent.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.sm),
              child: AnnouncementCard(
                key: ValueKey(a.id),
                group: g,
                announcement: a,
                showGroup: true,
                isNew: seen.isNew(g, a),
                maxLines: 3,
                onOpenGroup: () => context.push(Routes.group(g.id)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The student's groups, one tap away (the CR edits the routine there).
class _MyGroups extends StatelessWidget {
  const _MyGroups({required this.groups});

  final List<ClassGroup> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CsSection(
      title: l10n.classGroups,
      children: [
        for (final g in groups)
          CsRow(
            icon: CsIcons.groups,
            title: g.title,
            subtitle: [
              g.semester,
              l10n.classesCount(g.slots.length),
            ].join(' · '),
            trailing: g.isCr
                ? CsBadge(label: l10n.roleCr, tone: CsBadgeTone.success)
                : null,
            onTap: () => context.push(Routes.group(g.id)),
          ),
      ],
    );
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
            child: UserAvatar.of(user, size: 44),
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
      onTap: () => showClassSheet(context, item),
      child: _BrandCard(
        icon: CsIcons.time,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wraps, so a long badge never cuts the countdown off.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                if (item.moved || item.extra) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE68A),
                      borderRadius: BorderRadius.circular(CsRadius.full),
                    ),
                    child: Text(
                      item.movedFrom != null
                          ? l10n.movedFromDay(
                              shortDate(context, item.movedFrom!),
                            )
                          : item.moved
                          ? l10n.changeMoved
                          : l10n.changeExtra,
                      style: context.text.labelMedium?.copyWith(
                        color: const Color(0xFF78350F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                for (final t in item.group.assessmentsOn(
                  item.date,
                  s.courseCode,
                )) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFECACA),
                      borderRadius: BorderRadius.circular(CsRadius.full),
                    ),
                    child: Text(
                      assessmentKindText(l10n, t.kind),
                      style: context.text.labelMedium?.copyWith(
                        color: const Color(0xFF7F1D1D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 2),
                  child: Text(
                    timing,
                    style: context.text.labelLarge?.copyWith(color: white),
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
            if ((item.change?.note ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xs),
                child: CsLinkText(
                  item.change!.note,
                  style: soft?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: CsSpace.md),
            Wrap(
              spacing: CsSpace.md,
              runSpacing: CsSpace.xs,
              children: [
                _Meta(
                  icon: CsIcons.time,
                  text:
                      '${clockText(context, item.startMin)} – '
                      '${clockText(context, item.endMin)}',
                ),
                if (item.room.isNotEmpty)
                  _Meta(icon: CsIcons.room, text: l10n.roomShort(item.room)),
                if (s.teacher.isNotEmpty)
                  _Meta(icon: CsIcons.profile, text: s.teacher),
                if (s.kind == ClassKind.lab)
                  _Meta(icon: CsIcons.lab, text: l10n.classLab),
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
      final list = classesOn(
        groups,
        now.add(Duration(days: i)),
      ).where((c) => !c.off);
      if (list.isNotEmpty) next = list.first;
    }
    final crGroup = groups
        .where((g) => g.isCr && !g.isPersonal && g.slots.isEmpty)
        .firstOrNull;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final subtitle = next != null
        ? l10n.nextOn(DateFormat.MMMEd(locale).format(next.date))
        : (crGroup != null ? l10n.noClassesYetCr : l10n.noClassesYetMember);
    // Compact: a one-line header, then the next class as a plain row.
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.md,
          CsSpace.md,
          CsSpace.md,
          CsSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(CsRadius.sm + 2),
                  ),
                  child: Icon(
                    CsIcons.doneForToday,
                    size: 20,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleMedium),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: CsSpace.sm),
              Divider(height: 1, color: cs.border),
              ClassTile.on(
                next,
                groupTitle: groups.length > 1
                    ? groupLabel(context, next.group)
                    : null,
                onTap: () => showClassSheet(context, next!),
              ),
            ] else if (crGroup != null) ...[
              const SizedBox(height: CsSpace.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.newSlot(crGroup.id)),
                  icon: const Icon(CsIcons.add),
                  label: Text(l10n.addClass),
                ),
              ),
              const SizedBox(height: CsSpace.sm),
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
      icon: CsIcons.calendar,
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
            child: const Icon(CsIcons.groups, color: white),
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
            onPressed: () => context.push(Routes.findClass),
            icon: const Icon(CsIcons.search),
            label: Text(l10n.findClass),
          ),
          const SizedBox(height: CsSpace.xs),
          Wrap(
            spacing: CsSpace.xs,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: white),
                onPressed: () => context.push(Routes.joinGroup),
                icon: const Icon(CsIcons.key, size: 18),
                label: Text(l10n.joinWithCode),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: white),
                onPressed: () => context.push(Routes.newGroup),
                child: Text(l10n.imTheCr),
              ),
            ],
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
          Icon(CsIcons.offline, size: 18, color: cs.textSecondary),
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
