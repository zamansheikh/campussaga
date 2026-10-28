import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../bus_map.dart';

/// A still preview of the route on the map; tapping it opens the full map.
/// Still, so it doesn't fight the page's scrolling.
class BusRouteMapCard extends StatelessWidget {
  const BusRouteMapCard({
    super.key,
    required this.route,
    required this.onOpen,
    this.myStopId,
  });

  final BusRoute route;
  final String? myStopId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final points = routePoints(route);
    final missing = route.stops.length - points.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CsSectionTitle(
          title: l10n.busMapTitle,
          action: TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(CsIcons.map, size: 16),
            label: Text(l10n.busOpenMap),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(CsRadius.lg),
          child: SizedBox(
            height: 190,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 15,
                initialCameraFit: points.length > 1
                    ? CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(28),
                        maxZoom: 16,
                      )
                    : null,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
                onTap: (_, _) => onOpen(),
              ),
              children: [
                busTiles(context),
                routeLine(route),
                stopMarkers(route, myStopId: myStopId),
                const BusMapAttribution(),
              ],
            ),
          ),
        ),
        if (missing > 0)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.xs, left: CsSpace.xs),
            child: Text(
              l10n.busNotOnMap(missing),
              style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
            ),
          ),
      ],
    );
  }
}
