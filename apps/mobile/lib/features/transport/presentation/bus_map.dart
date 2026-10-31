import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart' show NumberFormat;
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

/// The route's line: along the roads when the server has worked the path
/// out, else straight between the placed stops.
List<LatLng> routeLinePoints(BusRoute route) {
  final path = route.path;
  if (path != null && path.isNotEmpty) {
    final pts = decodePolyline(path);
    if (pts.length >= 2) return [for (final p in pts) LatLng(p.lat, p.lng)];
  }
  return routePoints(route);
}

PolylineLayer routeLine(BusRoute route) => PolylineLayer(
  polylines: [
    Polyline(
      points: routeLinePoints(route),
      strokeWidth: 6,
      color: Color(route.argb),
      borderStrokeWidth: 2.5,
      borderColor: Colors.white.withValues(alpha: 0.95),
      strokeJoin: StrokeJoin.round,
      strokeCap: StrokeCap.round,
    ),
  ],
);

/// Which stops get their name next to the marker.
enum StopLabels {
  /// First, last, my stop and the selected one; all of them once zoomed in.
  auto,

  /// Every stop.
  all,
}

/// The placed stops as numbered markers with name labels; [onTap] gets the
/// stop. Labels follow the zoom so they don't pile up.
Widget stopMarkers(
  BusRoute route, {
  String? myStopId,
  String? selectedId,
  ValueChanged<BusStop>? onTap,
  StopLabels labels = StopLabels.auto,
}) => _StopMarkers(
  route: route,
  myStopId: myStopId,
  selectedId: selectedId,
  onTap: onTap,
  labels: labels,
);

class _StopMarkers extends StatelessWidget {
  const _StopMarkers({
    required this.route,
    required this.myStopId,
    required this.selectedId,
    required this.onTap,
    required this.labels,
  });

  final BusRoute route;
  final String? myStopId;
  final String? selectedId;
  final ValueChanged<BusStop>? onTap;
  final StopLabels labels;

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom;
    final color = Color(route.argb);
    final last = route.stops.length - 1;
    final markers = <Marker>[];
    // Plain stops first, so the important ones draw on top.
    final order =
        [
          for (final (i, s) in route.stops.indexed)
            if (s.hasLocation) (i, s),
        ]..sort(
          (a, b) => _rank(a.$1, a.$2, last).compareTo(_rank(b.$1, b.$2, last)),
        );
    for (final (i, s) in order) {
      final key = i == 0 || i == last || s.id == myStopId || s.id == selectedId;
      final showLabel = switch (labels) {
        StopLabels.all => true,
        StopLabels.auto => key || zoom >= 14.5,
      };
      markers.add(
        Marker(
          point: stopPoint(s)!,
          width: 168,
          height: 92,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap == null ? null : () => onTap!(s),
            child: Stack(
              alignment: Alignment.center,
              children: [
                StopDot(
                  number: i + 1,
                  color: color,
                  filled: s.id == myStopId || s.id == selectedId,
                  big: key,
                ),
                if (showLabel)
                  Positioned(
                    top: 46 + (key ? 17 : 14),
                    child: _Label(
                      text: s.name,
                      strong: key,
                      color: s.id == myStopId ? color : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return MarkerLayer(markers: markers);
  }

  int _rank(int i, BusStop s, int last) {
    if (s.id == selectedId) return 4;
    if (s.id == myStopId) return 3;
    if (i == 0 || i == last) return 2;
    return 1;
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.strong, this.color});

  final String text;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? cs.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.labelSmall?.copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              color: color == null ? cs.textPrimary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// The student's own position: a blue dot with its accuracy ring.
MarkerLayer meMarker(LatLng at) => MarkerLayer(
  markers: [
    Marker(
      point: at,
      width: 44,
      height: 44,
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB).withValues(alpha: 0.18),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
);

/// "650 m" or "2.4 km".
String distanceText(AppLocalizations l10n, double metres) => metres < 1000
    ? l10n.busDistanceM((metres / 10).round() * 10)
    : l10n.busDistanceKm((metres / 1000).toStringAsFixed(1));

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

/// Live buses (docs/BUS_LIVE.md) in the route's colour, with the number of
/// students sharing each. They glide to each new position rather than
/// jumping; a bus nobody has updated for [staleAfter] turns grey.
class LiveBusLayer extends StatefulWidget {
  const LiveBusLayer({
    super.key,
    required this.route,
    required this.runs,
    required this.now,
    this.staleAfter = const Duration(seconds: 90),
    this.onTap,
  });

  final BusRoute route;
  final List<BusRun> runs;
  final DateTime now;
  final Duration staleAfter;
  final ValueChanged<BusRun>? onTap;

  @override
  State<LiveBusLayer> createState() => _LiveBusLayerState();
}

class _LiveBusLayerState extends State<LiveBusLayer>
    with SingleTickerProviderStateMixin {
  late final _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
    value: 1,
  );
  final _from = <String, LatLng>{};
  var _to = <String, LatLng>{};

  static LatLng _point(BusRun r) => LatLng(r.lat, r.lng);

  @override
  void initState() {
    super.initState();
    _to = {for (final r in widget.runs) r.key: _point(r)};
  }

  @override
  void didUpdateWidget(LiveBusLayer old) {
    super.didUpdateWidget(old);
    final next = {for (final r in widget.runs) r.key: _point(r)};
    final moved = next.entries.any((e) => _to[e.key] != e.value);
    if (!moved) {
      _to = next;
      return;
    }
    final here = {for (final k in _to.keys) k: _at(k)};
    _from
      ..clear()
      ..addAll(here);
    _to = next;
    _move.forward(from: 0);
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  LatLng _at(String key) {
    final to = _to[key]!;
    final from = _from[key];
    if (from == null) return to;
    final t = Curves.easeInOut.transform(_move.value);
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _move,
    builder: (context, _) => MarkerLayer(
      markers: [
        for (final r in widget.runs)
          Marker(
            point: _at(r.key),
            width: 56,
            height: 56,
            child: GestureDetector(
              onTap: widget.onTap == null ? null : () => widget.onTap!(r),
              child: _BusMarker(
                color: widget.now.difference(r.updatedAt) > widget.staleAfter
                    ? context.cs.textSecondary
                    : Color(widget.route.argb),
                riders: r.riders,
                label: AppLocalizations.of(context).busLiveBus,
              ),
            ),
          ),
      ],
    ),
  );
}

class _BusMarker extends StatelessWidget {
  const _BusMarker({
    required this.color,
    required this.riders,
    required this.label,
  });

  final Color color;
  final int riders;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
          ),
          child: const Icon(CsIcons.bus, size: 20, color: Colors.white),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cs.error,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              NumberFormat.decimalPattern(
                Localizations.localeOf(context).toString(),
              ).format(riders),
              style: context.text.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
