import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../data/my_location.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';
import '../bus_map.dart';

/// The whole route on a map, along the roads, with each stop's name. The
/// strip at the bottom lists the stops with their next bus; "Where am I"
/// shows the student on the map with their nearest stop (location used on
/// the phone only, asked for on tap).
class BusRouteMapPage extends StatefulWidget {
  const BusRouteMapPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<BusRouteMapPage> createState() => _BusRouteMapPageState();
}

class _BusRouteMapPageState extends State<BusRouteMapPage> {
  final _cubit = getIt<BusCubit>();
  final _map = MapController();
  String? _selected;
  LatLng? _me;
  bool _locating = false;
  StreamSubscription<Position>? _follow;

  @override
  void dispose() {
    unawaited(_follow?.cancel());
    _map.dispose();
    super.dispose();
  }

  void _fitTo(List<LatLng> pts, EdgeInsets padding) {
    if (pts.length == 1) {
      _map.move(pts.first, 16);
    } else if (pts.length > 1) {
      _map.fitCamera(
        CameraFit.coordinates(coordinates: pts, padding: padding, maxZoom: 17),
      );
    }
  }

  void _fit(BusRoute r) => _fitTo([
    ...routeLinePoints(r),
    ?_me,
  ], const EdgeInsets.fromLTRB(48, 48, 48, 190));

  Future<void> _locate(BusRoute r) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    final res = await MyLocation.instance.current();
    if (!mounted) return;
    setState(() => _locating = false);
    final pos = res.position;
    final problem = res.problem;
    if (pos == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            problem == LocationProblem.serviceOff
                ? l10n.busLocationServiceOff
                : l10n.busLocationDenied,
          ),
          action: problem == null
              ? null
              : SnackBarAction(
                  label: l10n.busOpenSettings,
                  onPressed: () => MyLocation.instance.openSettings(problem),
                ),
        ),
      );
      return;
    }
    final me = LatLng(pos.latitude, pos.longitude);
    setState(() => _me = me);
    // Show me and my nearest stop together.
    final near = nearestStop(r, me.latitude, me.longitude);
    _fitTo([
      me,
      if (near != null) stopPoint(near.stop)!,
    ], const EdgeInsets.fromLTRB(64, 120, 64, 240));
    unawaited(_follow?.cancel());
    _follow = MyLocation.instance.updates().listen((p) {
      if (mounted) setState(() => _me = LatLng(p.latitude, p.longitude));
    }, onError: (Object _) {});
  }

  Future<void> _showStop(BusRoute r, BusStop s) async {
    final p = stopPoint(s);
    if (p == null) return;
    setState(() => _selected = s.id);
    _map.move(p, 16);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => _StopSheet(route: r, stop: s, cubit: _cubit, me: _me),
    );
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return BlocBuilder<BusCubit, BusState>(
      bloc: _cubit,
      builder: (context, s) {
        final r = s.route(widget.routeId);
        final points = r == null ? const <LatLng>[] : routeLinePoints(r);
        if (r == null || points.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: CsEmptyState(icon: CsIcons.map, title: l10n.busRouteNotFound),
          );
        }
        final myStop = s.myStops[r.id];
        final me = _me;
        final near = me == null
            ? null
            : nearestStop(r, me.latitude, me.longitude);
        return Scaffold(
          appBar: AppBar(
            title: Text(r.name),
            actions: [
              if (r.driverPhone.isNotEmpty)
                IconButton(
                  tooltip: r.driverName.isEmpty
                      ? l10n.busCallDriver
                      : l10n.busCallName(r.driverName),
                  onPressed: () => callPhone(r.driverPhone),
                  icon: const Icon(CsIcons.call),
                ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: points.first,
                  initialZoom: 15,
                  initialCameraFit: points.length > 1
                      ? CameraFit.coordinates(
                          coordinates: points,
                          padding: const EdgeInsets.fromLTRB(48, 48, 48, 190),
                          maxZoom: 17,
                        )
                      : null,
                  minZoom: 5,
                  maxZoom: 19,
                ),
                children: [
                  busTiles(context),
                  routeLine(r),
                  stopMarkers(
                    r,
                    myStopId: myStop,
                    selectedId: _selected,
                    onTap: (stop) => _showStop(r, stop),
                  ),
                  if (me != null) meMarker(me),
                  const BusMapAttribution(),
                ],
              ),
              Positioned(
                right: CsSpace.md,
                top: CsSpace.md,
                child: Column(
                  children: [
                    _MapButton(
                      tooltip: l10n.busFitRoute,
                      icon: CsIcons.map,
                      onPressed: () => _fit(r),
                    ),
                    const SizedBox(height: CsSpace.sm),
                    _MapButton(
                      tooltip: l10n.busWhereAmI,
                      icon: CsIcons.directions,
                      busy: _locating,
                      active: me != null,
                      onPressed: () => _locate(r),
                    ),
                  ],
                ),
              ),
              if (me != null)
                Positioned(
                  left: CsSpace.md,
                  top: CsSpace.md,
                  child: Material(
                    color: cs.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(CsRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CsSpace.sm,
                        vertical: 4,
                      ),
                      child: Text(
                        l10n.busLocationPrivate,
                        style: context.text.labelSmall,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (near != null)
                        _NearestCard(
                          near: near,
                          mine: near.stop.id == myStop,
                          onTap: () => _showStop(r, near.stop),
                          onSet: () => _cubit.setMyStop(r.id, near.stop.id),
                        ),
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(
                            CsSpace.md,
                            CsSpace.sm,
                            CsSpace.md,
                            CsSpace.md,
                          ),
                          itemCount: r.stops.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: CsSpace.sm),
                          itemBuilder: (context, i) => _StopChip(
                            route: r,
                            index: i,
                            selected: r.stops[i].id == _selected,
                            mine: r.stops[i].id == myStop,
                            onTap: r.stops[i].hasLocation
                                ? () => _showStop(r, r.stops[i])
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool busy;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: active ? cs.primary : cs.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: active ? cs.onPrimary : cs.textPrimary),
      ),
    );
  }
}

/// The soonest bus at [s], either way.
BusDeparture? _soonest(BusRoute r, BusStop s, DateTime now) {
  BusDeparture? best;
  for (final d in BusDirection.values) {
    final n = nextDepartures(
      r,
      stopId: s.id,
      direction: d,
      now: now,
      limit: 1,
    ).firstOrNull;
    if (n != null && (best == null || n.at.isBefore(best.at))) best = n;
  }
  return best;
}

class _StopChip extends StatelessWidget {
  const _StopChip({
    required this.route,
    required this.index,
    required this.selected,
    required this.mine,
    required this.onTap,
  });

  final BusRoute route;
  final int index;
  final bool selected;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final s = route.stops[index];
    final color = Color(route.argb);
    final next = _soonest(route, s, appNow());
    final when = next == null
        ? (s.hasLocation ? '—' : l10n.busLocationNone)
        : '${next.trip.direction == BusDirection.toCampus ? l10n.busToCampus : l10n.busFromCampus} '
              '${timeOf(context, next.at)}';
    return Material(
      color: cs.surface,
      elevation: selected ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(
          color: selected || mine ? color : cs.border,
          width: selected || mine ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 210),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: s.hasLocation ? 1 : 0.45,
                  child: StopDot(
                    number: index + 1,
                    color: color,
                    filled: mine,
                    big: true,
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                      Text(
                        when,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: next == null ? cs.textSecondary : cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _NearestCard extends StatelessWidget {
  const _NearestCard({
    required this.near,
    required this.mine,
    required this.onTap,
    required this.onSet,
  });

  final ({BusStop stop, double metres}) near;
  final bool mine;
  final VoidCallback onTap;
  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
      child: Material(
        color: cs.surface,
        elevation: 4,
        borderRadius: BorderRadius.circular(CsRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(CsRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(CsSpace.md, 10, 8, 10),
            child: Row(
              children: [
                const Icon(CsIcons.directions, color: Color(0xFF2563EB)),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: Text(
                    l10n.busNearestStop(
                      near.stop.name,
                      distanceText(l10n, near.metres),
                    ),
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!mine)
                  TextButton(onPressed: onSet, child: Text(l10n.busSetMyStop)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StopSheet extends StatelessWidget {
  const _StopSheet({
    required this.route,
    required this.stop,
    required this.cubit,
    this.me,
  });

  final BusRoute route;
  final BusStop stop;
  final BusCubit cubit;
  final LatLng? me;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final now = appNow();
    final mine = cubit.state.myStops[route.id] == stop.id;
    final here = me;
    final away = here == null || !stop.hasLocation
        ? null
        : distanceMetres(here.latitude, here.longitude, stop.lat!, stop.lng!);
    final next = [
      for (final d in BusDirection.values)
        (
          d,
          nextDepartures(
            route,
            stopId: stop.id,
            direction: d,
            now: now,
            limit: 1,
          ).firstOrNull,
        ),
    ];
    return Padding(
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
          Text(stop.name, style: context.text.titleLarge),
          if (stop.landmark.isNotEmpty || away != null)
            Text(
              [
                if (stop.landmark.isNotEmpty) stop.landmark,
                if (away != null) distanceText(l10n, away),
              ].join(' · '),
              style: context.text.bodyMedium?.copyWith(color: cs.textSecondary),
            ),
          const SizedBox(height: CsSpace.md),
          for (final (d, at) in next)
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.xs),
              child: Row(
                children: [
                  Icon(CsIcons.bus, size: 18, color: Color(route.argb)),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: Text(
                      d == BusDirection.toCampus
                          ? l10n.busToCampus
                          : l10n.busFromCampus,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  Text(
                    at == null
                        ? '—'
                        : '${timeOf(context, at.at)} · '
                              '${whenText(context, at.at, now)}',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: at == null ? cs.textSecondary : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: CsSpace.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openDirections(stop),
                  icon: const Icon(CsIcons.directions),
                  label: Text(l10n.busDirections),
                ),
              ),
              const SizedBox(width: CsSpace.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: mine
                      ? null
                      : () {
                          cubit.setMyStop(route.id, stop.id);
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(CsIcons.place),
                  label: Text(mine ? l10n.busMyStop : l10n.busSetMyStop),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
