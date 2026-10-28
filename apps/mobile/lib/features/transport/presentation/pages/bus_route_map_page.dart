import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';
import '../bus_map.dart';

/// The whole route on a map. Tapping a stop shows its next buses, with
/// "Set as my stop" and directions in the phone's maps app.
class BusRouteMapPage extends StatefulWidget {
  const BusRouteMapPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<BusRouteMapPage> createState() => _BusRouteMapPageState();
}

class _BusRouteMapPageState extends State<BusRouteMapPage> {
  final _cubit = getIt<BusCubit>();
  String? _selected;

  Future<void> _showStop(BusRoute r, BusStop s) async {
    setState(() => _selected = s.id);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => _StopSheet(route: r, stop: s, cubit: _cubit),
    );
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<BusCubit, BusState>(
      bloc: _cubit,
      builder: (context, s) {
        final r = s.route(widget.routeId);
        final points = r == null ? const <LatLng>[] : routePoints(r);
        if (r == null || points.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: CsEmptyState(icon: CsIcons.map, title: l10n.busRouteNotFound),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(r.name)),
          body: FlutterMap(
            options: MapOptions(
              initialCenter: points.first,
              initialZoom: 15,
              initialCameraFit: points.length > 1
                  ? CameraFit.coordinates(
                      coordinates: points,
                      padding: const EdgeInsets.all(48),
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
                myStopId: s.myStops[r.id],
                selectedId: _selected,
                onTap: (stop) => _showStop(r, stop),
              ),
              const BusMapAttribution(),
            ],
          ),
        );
      },
    );
  }
}

class _StopSheet extends StatelessWidget {
  const _StopSheet({
    required this.route,
    required this.stop,
    required this.cubit,
  });

  final BusRoute route;
  final BusStop stop;
  final BusCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final now = appNow();
    final mine = cubit.state.myStops[route.id] == stop.id;
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
          if (stop.landmark.isNotEmpty)
            Text(
              stop.landmark,
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
