import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../classes/presentation/class_format.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';

enum _Edit { route, stops, trips, delete }

/// One route: the next buses from my stop, the stops with this trip's
/// times, and every departure. Reps get the edit menu.
class BusRoutePage extends StatefulWidget {
  const BusRoutePage({super.key, required this.routeId});

  final String routeId;

  @override
  State<BusRoutePage> createState() => _BusRoutePageState();
}

class _BusRoutePageState extends State<BusRoutePage> {
  final _cubit = getIt<BusCubit>();
  late BusDirection _dir = appNow().hour < 12
      ? BusDirection.toCampus
      : BusDirection.fromCampus;

  @override
  void initState() {
    super.initState();
    // Opened straight from a link: load the routes first.
    final user = context.read<AuthBloc>().state.user;
    if (_cubit.state.routes == null && user != null) _cubit.open(user.id);
  }

  Future<void> _edit(BusRoute r, _Edit e) async {
    switch (e) {
      case _Edit.route:
        await context.push(Routes.busEdit(r.id));
      case _Edit.stops:
        await context.push(Routes.busStops(r.id));
      case _Edit.trips:
        await context.push(Routes.busTrips(r.id));
      case _Edit.delete:
        final l10n = AppLocalizations.of(context);
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text(l10n.busDeleteRouteTitle(r.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: d.cs.error),
                onPressed: () => Navigator.of(d).pop(true),
                child: Text(l10n.deleteAction),
              ),
            ],
          ),
        );
        if (!(ok ?? false) || !mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        try {
          await _cubit.deleteRoute(r.id);
          if (mounted) context.pop();
        } on Failure catch (f) {
          messenger.showSnackBar(
            SnackBar(content: Text(busErrorText(l10n, f))),
          );
        }
    }
  }

  Future<void> _pickStop(BusRoute r, String? current) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: CsSpace.md),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CsSpace.lg,
                  0,
                  CsSpace.lg,
                  CsSpace.sm,
                ),
                child: Text(l10n.busMyStop, style: sheet.text.titleMedium),
              ),
              for (final s in r.stops)
                ListTile(
                  leading: Icon(
                    s.id == current ? CsIcons.checkCircle : CsIcons.place,
                    color: s.id == current ? sheet.cs.primary : null,
                  ),
                  title: Text(s.name),
                  subtitle: s.landmark.isEmpty ? null : Text(s.landmark),
                  onTap: () => Navigator.of(sheet).pop(s.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await _cubit.setMyStop(r.id, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<BusCubit, BusState>(
      bloc: _cubit,
      builder: (context, s) {
        final r = s.route(widget.routeId);
        if (r == null) {
          return Scaffold(
            appBar: AppBar(),
            body: CsEmptyState(icon: CsIcons.bus, title: l10n.busRouteNotFound),
          );
        }
        final canEdit = s.routes?.canEdit ?? false;
        final now = appNow();
        final myStopId = s.myStops[r.id];
        final myStop = r.stops.where((x) => x.id == myStopId).firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(r.name),
            actions: [
              if (canEdit)
                PopupMenuButton<_Edit>(
                  icon: const Icon(CsIcons.more),
                  onSelected: (e) => _edit(r, e),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _Edit.route,
                      child: Text(l10n.busEditRoute),
                    ),
                    PopupMenuItem(
                      value: _Edit.stops,
                      child: Text(l10n.busEditStops),
                    ),
                    PopupMenuItem(
                      value: _Edit.trips,
                      child: Text(l10n.busEditTimetable),
                    ),
                    PopupMenuItem(
                      value: _Edit.delete,
                      child: Text(
                        l10n.busDeleteRoute,
                        style: TextStyle(color: context.cs.error),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                CsSpace.screen,
                CsSpace.sm,
                CsSpace.screen,
                CsSpace.xl,
              ),
              children: [
                if (r.notes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(CsRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(CsIcons.info, size: 18, color: context.cs.primary),
                        const SizedBox(width: CsSpace.sm),
                        Expanded(
                          child: Text(r.notes, style: context.text.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CsSpace.md),
                ],
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
                _MyStopCard(
                  route: r,
                  stop: myStop,
                  direction: _dir,
                  now: now,
                  onPick: () => _pickStop(r, myStopId),
                ),
                const SizedBox(height: CsSpace.lg),
                _StopsTimeline(
                  route: r,
                  direction: _dir,
                  now: now,
                  myStopId: myStopId,
                ),
                const SizedBox(height: CsSpace.lg),
                _Departures(route: r, direction: _dir),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyStopCard extends StatelessWidget {
  const _MyStopCard({
    required this.route,
    required this.stop,
    required this.direction,
    required this.now,
    required this.onPick,
  });

  final BusRoute route;
  final BusStop? stop;
  final BusDirection direction;
  final DateTime now;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final s = stop;
    if (s == null) {
      return OutlinedButton.icon(
        onPressed: route.stops.isEmpty ? null : onPick,
        icon: const Icon(CsIcons.place),
        label: Text(l10n.busPickStop),
      );
    }
    final next = nextDepartures(
      route,
      stopId: s.id,
      direction: direction,
      now: now,
      limit: 3,
    );
    return Container(
      padding: const EdgeInsets.all(CsSpace.md),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(CsRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CsIcons.place, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: CsSpace.xs),
              Expanded(
                child: Text(
                  l10n.busNextFrom(s.name),
                  style: context.text.titleSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.sm),
          if (next.isEmpty)
            Text(l10n.busNoMoreBuses, style: context.text.bodyMedium)
          else ...[
            Text(
              timeOf(context, next.first.at),
              style: context.text.headlineSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              whenText(context, next.first.at, now),
              style: context.text.bodyMedium?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
            if (next.length > 1) ...[
              const SizedBox(height: CsSpace.xs),
              Text(
                [
                  for (final d in next.skip(1))
                    '${dayText(context, d.at, now)} ${timeOf(context, d.at)}',
                ].join(' · '),
                style: context.text.bodySmall,
              ),
            ],
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onPick,
              child: Text(l10n.busChangeStop),
            ),
          ),
        ],
      ),
    );
  }
}

/// The stops in travel order, with the times of this direction's next trip.
class _StopsTimeline extends StatelessWidget {
  const _StopsTimeline({
    required this.route,
    required this.direction,
    required this.now,
    required this.myStopId,
  });

  final BusRoute route;
  final BusDirection direction;
  final DateTime now;
  final String? myStopId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final stops = direction == BusDirection.toCampus
        ? route.stops
        : route.stops.reversed.toList();
    if (stops.isEmpty) {
      return CsSection(
        title: l10n.busStopsTitle,
        children: [
          CsRow(
            icon: CsIcons.place,
            title: l10n.busNoStops,
            showChevron: false,
          ),
        ],
      );
    }
    // The next trip this way, timed at its first served stop.
    final first = stops.where((s) => s.offset(direction) != null).firstOrNull;
    final trip = first == null
        ? null
        : nextDepartures(
            route,
            stopId: first.id,
            direction: direction,
            now: now,
            limit: 1,
          ).firstOrNull;
    final start = trip?.at.subtract(
      Duration(minutes: first!.offset(direction)!),
    );
    final color = Color(route.argb);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: CsSpace.xs, bottom: CsSpace.sm),
          child: Text(
            l10n.busStopsTitle.toUpperCase(),
            style: context.text.labelMedium?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: cs.textSecondary,
            ),
          ),
        ),
        for (var i = 0; i < stops.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 64,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      start == null || stops[i].offset(direction) == null
                          ? '—'
                          : timeOf(
                              context,
                              start.add(
                                Duration(minutes: stops[i].offset(direction)!),
                              ),
                            ),
                      style: context.text.labelLarge?.copyWith(
                        color: stops[i].offset(direction) == null
                            ? cs.textSecondary
                            : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stops[i].id == myStopId ? color : cs.surface,
                          border: Border.all(color: color, width: 2.5),
                        ),
                      ),
                      if (i < stops.length - 1)
                        Expanded(
                          child: Container(
                            width: 2.5,
                            color: color.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: CsSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stops[i].name,
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: stops[i].id == myStopId
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (stops[i].landmark.isNotEmpty)
                          Text(
                            stops[i].landmark,
                            style: context.text.bodySmall?.copyWith(
                              color: cs.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Departures extends StatelessWidget {
  const _Departures({required this.route, required this.direction});

  final BusRoute route;
  final BusDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trips = route.trips.where((t) => t.direction == direction).toList()
      ..sort((a, b) => a.departsMin.compareTo(b.departsMin));
    final from = direction == BusDirection.toCampus
        ? route.stops.firstOrNull?.name
        : route.stops.lastOrNull?.name;
    return CsSection(
      title: l10n.busDepartures,
      children: [
        if (trips.isEmpty)
          CsRow(icon: CsIcons.time, title: l10n.busNoTrips, showChevron: false)
        else
          for (final t in trips)
            CsRow(
              icon: CsIcons.time,
              title: clockText(context, t.departsMin),
              subtitle: [
                weekdaysText(context, t.weekdays),
                if (from != null) l10n.busTripFirstStop(from),
                if (t.note.isNotEmpty) t.note,
              ].join(' · '),
              showChevron: false,
            ),
      ],
    );
  }
}
