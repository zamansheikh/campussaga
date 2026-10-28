import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map pieces shared by the route map, its preview and the stop picker.
/// Tiles come from OpenStreetMap (light use, with attribution, as its tile
/// policy asks).

/// The middle of Dhaka, when nothing nearer is known.
const busMapFallback = LatLng(23.8103, 90.4125);

LatLng? stopPoint(BusStop s) => s.hasLocation ? LatLng(s.lat!, s.lng!) : null;

/// The located stops of [route], in to-campus order.
List<LatLng> routePoints(BusRoute route) => [
  for (final s in route.stops) ?stopPoint(s),
];

/// OpenStreetMap tiles, dimmed to match the dark theme.
TileLayer busTiles(BuildContext context) => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.silifton.varsitykotha',
  maxNativeZoom: 19,
  tileBuilder: Theme.of(context).brightness == Brightness.dark
      ? darkModeTileBuilder
      : null,
);

/// "© OpenStreetMap contributors", which the tile licence requires.
class BusMapAttribution extends StatelessWidget {
  const BusMapAttribution({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomRight,
    child: Material(
      color: context.cs.surface.withValues(alpha: 0.8),
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(6)),
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            '© OpenStreetMap contributors',
            style: context.text.labelSmall?.copyWith(fontSize: 10),
          ),
        ),
      ),
    ),
  );
}

/// The route's line through its located stops.
PolylineLayer routeLine(BusRoute route) => PolylineLayer(
  polylines: [
    Polyline(
      points: routePoints(route),
      strokeWidth: 5,
      color: Color(route.argb).withValues(alpha: 0.85),
      borderStrokeWidth: 2,
      borderColor: Colors.white.withValues(alpha: 0.9),
    ),
  ],
);

/// A numbered marker for each located stop; [onTap] gets the stop.
MarkerLayer stopMarkers(
  BusRoute route, {
  String? myStopId,
  String? selectedId,
  ValueChanged<BusStop>? onTap,
}) {
  final color = Color(route.argb);
  return MarkerLayer(
    markers: [
      for (final (i, s) in route.stops.indexed)
        if (stopPoint(s) case final p?)
          Marker(
            point: p,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: onTap == null ? null : () => onTap(s),
              child: StopDot(
                number: i + 1,
                color: color,
                filled: s.id == myStopId || s.id == selectedId,
                big:
                    i == 0 ||
                    i == route.stops.length - 1 ||
                    s.id == myStopId ||
                    s.id == selectedId,
              ),
            ),
          ),
    ],
  );
}

/// A round stop marker with its number.
class StopDot extends StatelessWidget {
  const StopDot({
    super.key,
    required this.number,
    required this.color,
    this.filled = false,
    this.big = false,
  });

  final int number;
  final Color color;
  final bool filled;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 30.0 : 24.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.white,
          border: Border.all(color: filled ? Colors.white : color, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: big ? 12 : 10,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

/// Opens turn-by-turn directions to [s] in the phone's maps app.
Future<void> openDirections(BusStop s) => launchUrl(
  Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${s.lat},${s.lng}',
  }),
  mode: LaunchMode.externalApplication,
);
