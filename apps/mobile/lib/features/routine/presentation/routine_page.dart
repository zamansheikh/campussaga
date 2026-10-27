import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Weekly routine. R1: day strip + classes per day, with changes marked.
class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  late DateTime _selected = DateUtils.dateOnly(DateTime.now());

  /// Saturday-first week, as most Bangladeshi university routines are.
  List<DateTime> get _week {
    final today = DateUtils.dateOnly(DateTime.now());
    final fromSaturday = (today.weekday - DateTime.saturday) % 7;
    final start = today.subtract(Duration(days: fromSaturday));
    return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navRoutine)),
      body: CsPage(
        children: [
          _WeekStrip(
            days: _week,
            selected: _selected,
            onSelected: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: CsSpace.lg),
          Text(
            DateFormat.MMMMEEEEd(locale).format(_selected),
            style: context.text.titleMedium,
          ),
          const SizedBox(height: CsSpace.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CsSpace.md),
              child: CsEmptyState(
                icon: Icons.event_note_rounded,
                title: l10n.routineEmptyTitle,
                message: l10n.routineEmptyMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.dateOnly(DateTime.now());
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
    required this.onTap,
    required this.colors,
  });

  final String weekday;
  final String day;
  final bool selected;
  final bool today;
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
                    color: today
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
