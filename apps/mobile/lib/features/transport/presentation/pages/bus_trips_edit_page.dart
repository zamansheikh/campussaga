import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../classes/presentation/class_format.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';
import 'bus_stops_edit_page.dart' show confirmDiscard;

/// A route's timetable, one section per direction. Reps add several times
/// at once with the same days, pick the days from the usual patterns, and
/// can undo a removal. Pops with true once saved.
class BusTripsEditPage extends StatefulWidget {
  const BusTripsEditPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<BusTripsEditPage> createState() => _BusTripsEditPageState();
}

class _Row {
  _Row(this.key, this.trip);

  final int key;
  BusTrip trip;
}

class _BusTripsEditPageState extends State<BusTripsEditPage> {
  final _cubit = getIt<BusCubit>();
  late final BusRoute? _route = _cubit.state.route(widget.routeId);
  late final List<_Row> _rows = [
    for (final (i, t) in (_route?.trips ?? const <BusTrip>[]).indexed)
      _Row(i, t),
  ];
  late int _nextKey = _rows.length;
  bool _dirty = false;
  bool _saving = false;

  void _change(VoidCallback f) => setState(() {
    f();
    _dirty = true;
  });

  List<_Row> _of(BusDirection d) =>
      _rows.where((r) => r.trip.direction == d).toList()
        ..sort((a, b) => a.trip.departsMin.compareTo(b.trip.departsMin));

  Future<void> _add(BusDirection dir) async {
    final same = _of(dir);
    final last = same.lastOrNull?.trip;
    final trips = await showModalBottomSheet<List<BusTrip>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TripSheet(
        direction: dir,
        times: [
          if (last != null)
            (last.departsMin + 30).clamp(0, 23 * 60 + 59)
          else if (dir == BusDirection.toCampus)
            7 * 60 + 30
          else
            17 * 60,
        ],
        days: last?.weekdays ?? BusDays.satToThu,
        note: '',
      ),
    );
    if (trips == null || !mounted) return;
    _change(() {
      for (final t in trips) {
        _rows.add(_Row(_nextKey++, t));
      }
    });
  }

  Future<void> _edit(_Row row) async {
    final res = await showModalBottomSheet<List<BusTrip>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TripSheet(
        direction: row.trip.direction,
        times: [row.trip.departsMin],
        days: row.trip.weekdays,
        note: row.trip.note,
        editing: true,
      ),
    );
    if (res == null || !mounted) return;
    if (res.isEmpty) {
      _remove(row);
    } else {
      _change(() => row.trip = res.first);
    }
  }

  void _remove(_Row row) {
    final l10n = AppLocalizations.of(context);
    final at = _rows.indexOf(row);
    if (at < 0) return;
    _change(() => _rows.removeAt(at));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.busDepartureRemoved),
          action: SnackBarAction(
            label: l10n.busUndo,
            onPressed: () {
              if (mounted) {
                _change(() => _rows.insert(at.clamp(0, _rows.length), row));
              }
            },
          ),
        ),
      );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _cubit.setTrips(widget.routeId, [for (final r in _rows) r.trip]);
      if (!mounted) return;
      _dirty = false;
      messenger.showSnackBar(SnackBar(content: Text(l10n.busSaved)));
      context.pop(true);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(busErrorText(l10n, f))));
    }
  }

  Future<void> _maybeLeave() async {
    if (await confirmDiscard(context) && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stops = _route?.stops ?? const <BusStop>[];
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybeLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.busEditTimetable),
          actions: [
            CsBarButton(
              label: l10n.busSave,
              busy: _saving,
              onPressed: _dirty ? _save : null,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_saving) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CsSpace.screen,
                  CsSpace.sm,
                  CsSpace.screen,
                  CsSpace.xl,
                ),
                children: [
                  for (final dir in BusDirection.values) ...[
                    _DirectionSection(
                      title: dir == BusDirection.toCampus
                          ? l10n.busToCampus
                          : l10n.busFromCampus,
                      from: dir == BusDirection.toCampus
                          ? stops.firstOrNull?.name
                          : stops.lastOrNull?.name,
                      rows: _of(dir),
                      onAdd: () => _add(dir),
                      onEdit: _edit,
                      onRemove: _remove,
                    ),
                    const SizedBox(height: CsSpace.lg),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionSection extends StatelessWidget {
  const _DirectionSection({
    required this.title,
    required this.from,
    required this.rows,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final String? from;
  final List<_Row> rows;
  final VoidCallback onAdd;
  final ValueChanged<_Row> onEdit;
  final ValueChanged<_Row> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium),
                  if (from != null)
                    Text(
                      l10n.busLeavesFrom(from!),
                      style: context.text.bodySmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(CsIcons.add),
              label: Text(l10n.busAddTimes),
            ),
          ],
        ),
        const SizedBox(height: CsSpace.sm),
        Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CsRadius.lg),
            side: BorderSide(color: cs.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(CsSpace.md),
                  child: Text(
                    l10n.busNoTrips,
                    style: context.text.bodyMedium?.copyWith(
                      color: cs.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, r) in rows.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      Dismissible(
                        key: ValueKey(r.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: cs.error,
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsets.symmetric(
                            horizontal: CsSpace.lg,
                          ),
                          child: Icon(CsIcons.delete, color: cs.onError),
                        ),
                        onDismissed: (_) => onRemove(r),
                        child: ListTile(
                          leading: const Icon(CsIcons.time),
                          title: Text(
                            clockText(context, r.trip.departsMin),
                            style: context.text.titleMedium,
                          ),
                          subtitle: Text(
                            [
                              weekdaysText(context, r.trip.weekdays),
                              if (r.trip.note.isNotEmpty) r.trip.note,
                            ].join(' · '),
                          ),
                          trailing: IconButton(
                            tooltip: l10n.deleteAction,
                            icon: const Icon(CsIcons.delete),
                            onPressed: () => onRemove(r),
                          ),
                          onTap: () => onEdit(r),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Adds one or more departures (same direction, days and note), or edits
/// one. Pops with the trips; an empty list removes the edited one.
class _TripSheet extends StatefulWidget {
  const _TripSheet({
    required this.direction,
    required this.times,
    required this.days,
    required this.note,
    this.editing = false,
  });

  final BusDirection direction;
  final List<int> times;
  final Set<int> days;
  final String note;
  final bool editing;

  @override
  State<_TripSheet> createState() => _TripSheetState();
}

class _TripSheetState extends State<_TripSheet> {
  late BusDirection _dir = widget.direction;
  late final List<int> _times = [...widget.times];
  late final Set<int> _days = {...widget.days};
  late final _note = TextEditingController(text: widget.note);
  String? _error;

  static const _presets = [BusDays.satToThu, BusDays.friSat, BusDays.everyDay];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime([int? index]) async {
    final start = index == null
        ? (_times.isEmpty ? 7 * 60 + 30 : (_times.last + 30) % (24 * 60))
        : _times[index];
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60),
    );
    if (t == null || !mounted) return;
    final m = t.hour * 60 + t.minute;
    setState(() {
      _error = null;
      if (index == null) {
        if (!_times.contains(m)) _times.add(m);
      } else {
        _times[index] = m;
      }
      _times.sort();
    });
  }

  void _done() {
    final l10n = AppLocalizations.of(context);
    if (_times.isEmpty) {
      setState(() => _error = l10n.busPickTime);
      return;
    }
    if (_days.isEmpty) {
      setState(() => _error = l10n.busPickDay);
      return;
    }
    Navigator.of(context).pop([
      for (final m in _times)
        BusTrip(
          direction: _dir,
          departsMin: m,
          weekdays: {..._days},
          note: _note.text.trim(),
        ),
    ]);
  }

  bool _same(Set<int> a) => a.length == _days.length && a.containsAll(_days);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.screen,
          CsSpace.sm,
          CsSpace.screen,
          CsSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.editing ? l10n.editAction : l10n.busAddDeparture,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: CsSpace.md),
            SegmentedButton<BusDirection>(
              segments: [
                ButtonSegment(
                  value: BusDirection.toCampus,
                  label: Text(l10n.busToCampus),
                ),
                ButtonSegment(
                  value: BusDirection.fromCampus,
                  label: Text(l10n.busFromCampus),
                ),
              ],
              selected: {_dir},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _dir = v.first),
            ),
            const SizedBox(height: CsSpace.md),
            Text(l10n.busDepartsAt, style: context.text.labelLarge),
            const SizedBox(height: CsSpace.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (i, m) in _times.indexed)
                  InputChip(
                    label: Text(
                      clockText(context, m),
                      style: context.text.titleSmall,
                    ),
                    onPressed: () => _pickTime(i),
                    onDeleted: widget.editing || _times.length == 1
                        ? null
                        : () => setState(() => _times.removeAt(i)),
                  ),
                if (!widget.editing)
                  ActionChip(
                    avatar: const Icon(CsIcons.add, size: 18),
                    label: Text(l10n.busAddAnotherTime),
                    onPressed: _pickTime,
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            Text(l10n.busWeekdays, style: context.text.labelLarge),
            const SizedBox(height: CsSpace.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in _presets)
                  ChoiceChip(
                    label: Text(weekdaysText(context, p)),
                    selected: _same(p),
                    onSelected: (_) => setState(() {
                      _days
                        ..clear()
                        ..addAll(p);
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in weekOrder)
                  FilterChip(
                    label: Text(weekdayShort(context, d)),
                    selected: _days.contains(d),
                    showCheckmark: false,
                    onSelected: (on) => setState(() {
                      on ? _days.add(d) : _days.remove(d);
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.sm),
            TextField(
              controller: _note,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: l10n.busTripNote,
                counterText: '',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: CsSpace.sm),
                child: Text(
                  _error!,
                  style: context.text.bodySmall?.copyWith(color: cs.error),
                ),
              ),
            Row(
              children: [
                if (widget.editing)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    onPressed: () => Navigator.of(context).pop(<BusTrip>[]),
                    icon: const Icon(CsIcons.delete),
                    label: Text(l10n.deleteAction),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _done,
                  child: Text(
                    widget.editing
                        ? l10n.busSave
                        : l10n.busAddDepartures(_times.length),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
