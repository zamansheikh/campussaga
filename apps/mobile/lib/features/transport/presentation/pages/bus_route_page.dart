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
import '../bus_map.dart';
import '../widgets/bus_route_map_card.dart';

enum _Edit { route, stops, trips, delete }

/// One route: the next buses from my stop, the map, the stops with this
/// trip's times, and every departure. Reps get edit buttons, and a setup
/// guide while the route has no stops or times.
class BusRoutePage extends StatefulWidget {
  const BusRoutePage({super.key, required this.routeId, this.setup = false});

  final String routeId;

  /// Just created: go straight to adding stops, then departure times.
  final bool setup;

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
    if (widget.setup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _editStops());
    }
  }

  /// Stops first; a route saved with stops but no times goes on to them.
  Future<void> _editStops() async {
    final saved = await context.push<bool>(Routes.busStops(widget.routeId));
    if (saved != true || !mounted) return;
    final r = _cubit.state.route(widget.routeId);
    if (r != null && r.stops.isNotEmpty && r.trips.isEmpty) {
      await context.push<bool>(Routes.busTrips(widget.routeId));
    }
  }

  Future<void> _editTrips() =>
      context.push<bool>(Routes.busTrips(widget.routeId));

  Future<void> _edit(BusRoute r, _Edit e) async {
    switch (e) {
      case _Edit.route:
        await context.push(Routes.busEdit(r.id));
      case _Edit.stops:
        await _editStops();
      case _Edit.trips:
        await _editTrips();
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
                          child: CsLinkText(
                            r.notes,
                            style: context.text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CsSpace.md),
                ],
                if (r.driverPhone.isNotEmpty) ...[
                  _DriverCard(route: r),
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
                if (canEdit && (r.stops.isEmpty || r.trips.isEmpty)) ...[
                  _SetupCard(
                    route: r,
                    onStops: _editStops,
                    onTimes: _editTrips,
                  ),
                  const SizedBox(height: CsSpace.md),
                ],
                _MyStopCard(
                  route: r,
                  stop: myStop,
                  direction: _dir,
                  now: now,
                  onPick: () => _pickStop(r, myStopId),
                ),
                if (routePoints(r).isNotEmpty) ...[
                  const SizedBox(height: CsSpace.lg),
                  BusRouteMapCard(
                    route: r,
                    myStopId: myStopId,
                    onOpen: () => context.push(Routes.busMap(r.id)),
                  ),
                ] else if (canEdit && r.stops.isNotEmpty) ...[
                  const SizedBox(height: CsSpace.md),
                  OutlinedButton.icon(
                    onPressed: _editStops,
                    icon: const Icon(CsIcons.placeAdd),
                    label: Text(l10n.busSetupMap),
                  ),
                ],
                const SizedBox(height: CsSpace.lg),
                _StopsTimeline(
                  route: r,
                  direction: _dir,
                  now: now,
                  myStopId: myStopId,
                  onEdit: canEdit ? _editStops : null,
                ),
                const SizedBox(height: CsSpace.lg),
                _Departures(
                  route: r,
                  direction: _dir,
                  onEdit: canEdit ? _editTrips : null,
                ),
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

  /// Why there's no time for [s]: no buses this way, no time listed for
  /// this stop (then when the bus leaves its first timed stop), or none
  /// left this week.
  String _noBusText(BuildContext context, BusStop s) {
    final l10n = AppLocalizations.of(context);
    if (!route.trips.any((t) => t.direction == direction)) {
      return direction == BusDirection.toCampus
          ? l10n.busNoTripsToCampus
          : l10n.busNoTripsFromCampus;
    }
    if (s.offset(direction) != null) return l10n.busNoMoreBuses;
    final ordered = direction == BusDirection.toCampus
        ? route.stops
        : route.stops.reversed;
    final first = ordered.where((x) => x.offset(direction) != null).firstOrNull;
    final at = first == null
        ? null
        : nextDepartures(
            route,
            stopId: first.id,
            direction: direction,
            now: now,
            limit: 1,
          ).firstOrNull;
    if (first == null || at == null) return l10n.busStopNoTime(s.name);
    return '${l10n.busStopNoTime(s.name)} '
        '${l10n.busRouteLeaves(first.name, timeOf(context, at.at))} '
        '(${whenText(context, at.at, now)})';
  }

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
    final why = next.isEmpty ? _noBusText(context, s) : null;
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
          if (why != null)
            Text(why, style: context.text.bodyMedium)
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
    this.onEdit,
  });

  final BusRoute route;
  final BusDirection direction;
  final DateTime now;
  final String? myStopId;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final stops = direction == BusDirection.toCampus
        ? route.stops
        : route.stops.reversed.toList();
    final action = onEdit == null ? null : _EditButton(onPressed: onEdit!);
    if (stops.isEmpty) {
      return CsSection(
        title: l10n.busStopsTitle,
        action: action,
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
        CsSectionTitle(title: l10n.busStopsTitle, action: action),
        if (action != null) const SizedBox(height: CsSpace.xs),
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
  const _Departures({
    required this.route,
    required this.direction,
    this.onEdit,
  });

  final BusRoute route;
  final BusDirection direction;
  final VoidCallback? onEdit;

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
      action: onEdit == null ? null : _EditButton(onPressed: onEdit!),
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

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(CsIcons.edit, size: 16),
    label: Text(AppLocalizations.of(context).busEdit),
  );
}

/// For transport reps while a route has no stops or no times yet.
class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.route,
    required this.onStops,
    required this.onTimes,
  });

  final BusRoute route;
  final VoidCallback onStops;
  final VoidCallback onTimes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    Widget step(int n, String title, bool done, VoidCallback? onTap) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: onTap != null || done,
          leading: done
              ? Icon(CsIcons.checkCircle, color: cs.primary)
              : CircleAvatar(
                  radius: 12,
                  backgroundColor: onTap == null ? cs.border : cs.primary,
                  foregroundColor: cs.onPrimary,
                  child: Text(
                    '$n',
                    style: context.text.labelMedium?.copyWith(
                      color: cs.onPrimary,
                    ),
                  ),
                ),
          title: Text(
            title,
            style: done
                ? context.text.bodyLarge?.copyWith(
                    color: cs.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  )
                : context.text.bodyLarge,
          ),
          trailing: done || onTap == null
              ? null
              : Icon(CsIcons.chevronRight, color: cs.textSecondary),
          onTap: done ? null : onTap,
        );
    final hasStops = route.stops.isNotEmpty;
    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.md,
          CsSpace.md,
          CsSpace.md,
          CsSpace.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.busSetupTitle, style: context.text.titleSmall),
            const SizedBox(height: 2),
            Text(
              l10n.busSetupBody,
              style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
            ),
            step(1, l10n.busSetupStops, hasStops, onStops),
            step(
              2,
              l10n.busSetupTimes,
              route.trips.isNotEmpty,
              hasStops ? onTimes : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The route's driver with a call button (opens the dialer).
class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.route});

  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final name = route.driverName;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(CsSpace.md, 10, 10, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(route.argb).withValues(alpha: 0.15),
              child: Icon(CsIcons.bus, color: Color(route.argb)),
            ),
            const SizedBox(width: CsSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l10n.busDriver : name,
                    style: context.text.titleSmall,
                  ),
                  Text(
                    name.isEmpty
                        ? route.driverPhone
                        : '${l10n.busDriver} · ${route.driverPhone}',
                    style: context.text.bodySmall?.copyWith(
                      color: cs.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => callPhone(route.driverPhone),
              icon: const Icon(CsIcons.call, size: 18),
              label: Text(l10n.busCallDriver),
            ),
          ],
        ),
      ),
    );
  }
}
