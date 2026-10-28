import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/clock.dart';
import '../../../app/router.dart';
import '../../classes/presentation/bloc/my_classes_cubit.dart';
import '../../classes/presentation/class_format.dart';
import '../../classes/presentation/widgets/class_sheet.dart';
import '../../classes/presentation/widgets/class_tile.dart';

/// Weekly routine. R1: day strip + classes per day, with changes marked.
class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  late DateTime _selected = DateUtils.dateOnly(appNow());

  /// Saturday-first week, as most Bangladeshi university routines are.
  List<DateTime> get _week {
    final today = DateUtils.dateOnly(appNow());
    final fromSaturday = (today.weekday - DateTime.saturday) % 7;
    final start = today.subtract(Duration(days: fromSaturday));
    return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final classes = context.watch<MyClassesCubit>().state;
    final routine = classes.routine;
    final day = classesOn(routine, _selected);
    final busyDays = {
      for (final g in routine)
        for (final s in g.slots)
          if (!g.hides(s.courseCode)) s.weekday,
    };
    final crGroups = classes.groups.where((g) => g.isCr).toList();
    final today = DateUtils.dateOnly(appNow());
    return Scaffold(
      floatingActionButton: _selected.isBefore(today)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context, crGroups),
              icon: const Icon(CsIcons.add),
              label: Text(l10n.addAction),
            ),
      appBar: AppBar(
        title: Text(l10n.navRoutine),
        actions: [
          IconButton(
            tooltip: l10n.classGroups,
            onPressed: () => context.push(Routes.groups),
            icon: const Icon(CsIcons.groups),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<MyClassesCubit>().refresh,
        child: CsPage(
          children: [
            _WeekStrip(
              days: _week,
              selected: _selected,
              busyDays: busyDays,
              onSelected: (d) => setState(() => _selected = d),
            ),
            const SizedBox(height: CsSpace.lg),
            Text(
              DateFormat.MMMMEEEEd(locale).format(_selected),
              style: context.text.titleMedium,
            ),
            const SizedBox(height: CsSpace.md),
            if (!classes.hasGroups && classes.personal.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: CsSpace.md),
                  child: CsEmptyState(
                    icon: CsIcons.routineNote,
                    title: l10n.routineEmptyTitle,
                    message: l10n.routineEmptyMessage,
                    actionLabel: l10n.joinClassGroup,
                    onAction: () => context.push(Routes.groups),
                  ),
                ),
              )
            else if (day.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(CsSpace.lg),
                  child: Row(
                    children: [
                      Icon(CsIcons.dateCheck, color: context.cs.textSecondary),
                      const SizedBox(width: CsSpace.md),
                      Expanded(
                        child: Text(
                          l10n.routineNoClassesDay,
                          style: context.text.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              CsSection(
                children: [
                  for (final c in day)
                    ClassTile.on(
                      c,
                      groupTitle: routine.length > 1
                          ? groupLabel(context, c.group)
                          : null,
                      onTap: () => showClassSheet(context, c),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

extension on _RoutinePageState {
  /// A personal class, or (CRs) an extra class on the selected date.
  Future<void> _add(BuildContext context, List<ClassGroup> crGroups) async {
    final l10n = AppLocalizations.of(context);
    if (crGroups.isEmpty) {
      await context.push(Routes.newPersonal);
      return;
    }
    final what = await CsOptionSheet.show<String>(
      context: context,
      title: l10n.addToRoutine,
      selected: '',
      options: [
        CsOption(
          'personal',
          l10n.addPersonalClass,
          subtitle: l10n.personalHint,
          icon: CsIcons.profile,
        ),
        CsOption(
          'extra',
          l10n.addExtraClass,
          subtitle: l10n.extraClassHint,
          icon: CsIcons.dateCheck,
        ),
      ],
    );
    if (!context.mounted || what == null) return;
    if (what == 'personal') {
      await context.push(Routes.newPersonal);
    } else {
      await _addExtra(context, crGroups);
    }
  }

  /// Extra class on the selected date; asks which group if CR of several.
  Future<void> _addExtra(BuildContext context, List<ClassGroup> groups) async {
    final l10n = AppLocalizations.of(context);
    var g = groups.first;
    if (groups.length > 1) {
      final id = await CsOptionSheet.show<String>(
        context: context,
        title: l10n.classGroups,
        selected: '',
        options: [
          for (final x in groups) CsOption(x.id, x.title, subtitle: x.semester),
        ],
      );
      if (id == null || !context.mounted) return;
      g = groups.firstWhere((x) => x.id == id);
    }
    await context.push(Routes.extraClass(g.id, _selected));
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.busyDays,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime selected;

  /// Weekdays that have classes get a dot.
  final Set<int> busyDays;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.dateOnly(appNow());
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _Day(
                weekday: DateFormat.E(locale).format(d),
                day: DateFormat.d(locale).format(d),
                selected: d == selected,
                today: d == today,
                busy: busyDays.contains(d.weekday),
                onTap: () => onSelected(d),
                colors: cs,
              ),
            ),
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.today,
    required this.busy,
    required this.onTap,
    required this.colors,
  });

  final String weekday;
  final String day;
  final bool selected;
  final bool today;
  final bool busy;
  final VoidCallback onTap;
  final CsColors colors;

  @override
  Widget build(BuildContext context) {
    final cs = colors;
    final fg = selected ? cs.onPrimary : cs.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? cs.primary : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
          side: BorderSide(
            color: selected
                ? cs.primary
                : today
                ? cs.primary.withValues(alpha: 0.5)
                : cs.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(
                  weekday,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: context.text.labelSmall?.copyWith(
                    color: selected
                        ? cs.onPrimary.withValues(alpha: 0.85)
                        : cs.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(day, style: context.text.titleMedium?.copyWith(color: fg)),
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: busy
                        ? (selected ? cs.onPrimary : cs.primary)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
