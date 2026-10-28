import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../classes/presentation/class_format.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';

/// A route's departures: each one a time, a direction and its days.
class BusTripsEditPage extends StatefulWidget {
  const BusTripsEditPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<BusTripsEditPage> createState() => _BusTripsEditPageState();
}

class _BusTripsEditPageState extends State<BusTripsEditPage> {
  final _cubit = getIt<BusCubit>();
  late final _trips = [...?_cubit.state.route(widget.routeId)?.trips];
  bool _saving = false;

  void _sort() => _trips.sort((a, b) {
    final d = a.direction.index.compareTo(b.direction.index);
    return d != 0 ? d : a.departsMin.compareTo(b.departsMin);
  });

  Future<void> _editTrip([int? index]) async {
    final trip = await showDialog<BusTrip>(
      context: context,
      builder: (_) => _TripDialog(trip: index == null ? null : _trips[index]),
    );
    if (trip == null) return;
    setState(() {
      if (index == null) {
        _trips.add(trip);
      } else {
        _trips[index] = trip;
      }
      _sort();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _cubit.setTrips(widget.routeId, _trips);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.busSaved)));
      context.pop();
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(busErrorText(l10n, f))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.busEditTimetable),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.busSave),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _editTrip,
        icon: const Icon(CsIcons.add),
        label: Text(l10n.busAddDeparture),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saving) const LinearProgressIndicator(),
          Expanded(
            child: _trips.isEmpty
                ? CsEmptyState(icon: CsIcons.time, title: l10n.busNoTrips)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      CsSpace.screen,
                      CsSpace.sm,
                      CsSpace.screen,
                      96,
                    ),
                    children: [
                      for (final dir in BusDirection.values)
                        if (_trips.any((t) => t.direction == dir)) ...[
                          CsSection(
                            title: dir == BusDirection.toCampus
                                ? l10n.busToCampus
                                : l10n.busFromCampus,
                            children: [
                              for (final (i, t) in _trips.indexed)
                                if (t.direction == dir)
                                  CsRow(
                                    icon: CsIcons.time,
                                    title: clockText(context, t.departsMin),
                                    subtitle: [
                                      weekdaysText(context, t.weekdays),
                                      if (t.note.isNotEmpty) t.note,
                                    ].join(' · '),
                                    onTap: () => _editTrip(i),
                                    showChevron: false,
                                    trailing: IconButton(
                                      tooltip: l10n.deleteAction,
                                      icon: const Icon(CsIcons.delete),
                                      onPressed: () =>
                                          setState(() => _trips.removeAt(i)),
                                    ),
                                  ),
                            ],
                          ),
                          const SizedBox(height: CsSpace.md),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TripDialog extends StatefulWidget {
  const _TripDialog({this.trip});

  final BusTrip? trip;

  @override
  State<_TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<_TripDialog> {
  late BusDirection _dir = widget.trip?.direction ?? BusDirection.toCampus;
  late int _departs = widget.trip?.departsMin ?? 7 * 60 + 30;
  // Saturday to Thursday: the usual Bangladesh week.
  late final Set<int> _days = {...?widget.trip?.weekdays};
  late final _note = TextEditingController(text: widget.trip?.note ?? '');
  bool _dayError = false;

  @override
  void initState() {
    super.initState();
    if (widget.trip == null) _days.addAll(const [6, 7, 1, 2, 3, 4]);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _departs ~/ 60, minute: _departs % 60),
    );
    if (t != null) setState(() => _departs = t.hour * 60 + t.minute);
  }

  void _done() {
    if (_days.isEmpty) {
      setState(() => _dayError = true);
      return;
    }
    Navigator.of(context).pop(
      BusTrip(
        id: widget.trip?.id ?? '',
        direction: _dir,
        departsMin: _departs,
        weekdays: {..._days},
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.trip == null ? l10n.busAddDeparture : l10n.editAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CsIcons.time),
              title: Text(l10n.busDepartsAt),
              trailing: Text(
                clockText(context, _departs),
                style: context.text.titleMedium,
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: CsSpace.sm),
            Text(l10n.busWeekdays, style: context.text.labelLarge),
            const SizedBox(height: CsSpace.xs),
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
                      _dayError = false;
                    }),
                  ),
              ],
            ),
            if (_dayError)
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xs),
                child: Text(
                  l10n.busPickDay,
                  style: context.text.bodySmall?.copyWith(
                    color: context.cs.error,
                  ),
                ),
              ),
            const SizedBox(height: CsSpace.sm),
            TextField(
              controller: _note,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.busTripNote),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _done, child: Text(l10n.busSave)),
      ],
    );
  }
}
