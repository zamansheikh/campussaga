import 'dart:async';

import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/place_search.dart';
import '../bus_map.dart';

/// Places one stop: move the map until the pin sits on the stop, or search
/// for the place by name. Pops with the chosen point (null: cancelled).
/// Uses no phone location, so it asks for no permission.
class StopLocationPage extends StatefulWidget {
  const StopLocationPage({
    super.key,
    required this.stopName,
    required this.color,
    this.initial,
    this.near,
    this.others = const [],
    this.search,
  });

  final String stopName;
  final Color color;

  /// Where the stop is now, if it's placed.
  final LatLng? initial;

  /// Where to start when it isn't: a stop next to it, or the route.
  final LatLng? near;

  /// The route's other placed stops, shown for context.
  final List<LatLng> others;

  /// Place search (tests pass a fake).
  final PlaceSearch? search;

  static Future<LatLng?> open(
    BuildContext context, {
    required String stopName,
    required Color color,
    LatLng? initial,
    LatLng? near,
    List<LatLng> others = const [],
  }) => Navigator.of(context).push<LatLng>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => StopLocationPage(
        stopName: stopName,
        color: color,
        initial: initial,
        near: near,
        others: others,
      ),
    ),
  );

  @override
  State<StopLocationPage> createState() => _StopLocationPageState();
}

class _StopLocationPageState extends State<StopLocationPage> {
  final _map = MapController();
  late final _search = widget.search ?? PlaceSearch();
  late final _query = TextEditingController(
    text: widget.initial == null ? widget.stopName : '',
  );
  late LatLng _center = widget.initial ?? widget.near ?? busMapFallback;
  List<Place>? _results;
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    // A new stop: look its name up straight away, so one tap places it.
    if (widget.initial == null && widget.stopName.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _find());
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final l10n = AppLocalizations.of(context);
    final q = _query.text.trim();
    if (q.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final found = await _search.search(
        q,
        near: widget.near ?? widget.initial,
      );
      if (!mounted) return;
      setState(() {
        _results = found;
        _searchError = found.isEmpty ? l10n.busSearchNoResults : null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _results = null;
        _searchError = l10n.busSearchFailed;
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _go(Place p) {
    setState(() {
      _results = null;
      _center = p.point;
    });
    _map.move(p.point, 17);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.busPickerTitle(widget.stopName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial != null
                  ? 17
                  : widget.near != null
                  ? 14
                  : 12,
              minZoom: 5,
              maxZoom: 19,
              onPositionChanged: (camera, _) => _center = camera.center,
              onTap: (_, _) => FocusScope.of(context).unfocus(),
            ),
            children: [
              busTiles(context),
              MarkerLayer(
                markers: [
                  for (final p in widget.others)
                    Marker(
                      point: p,
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: widget.color, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
              const BusMapAttribution(),
            ],
          ),
          // The pin: its tip marks the middle of the map.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: Icon(CsIcons.placeFill, size: 44, color: widget.color),
              ),
            ),
          ),
          Positioned(
            left: CsSpace.md,
            right: CsSpace.md,
            top: CsSpace.md,
            child: Material(
              elevation: 3,
              color: cs.surface,
              borderRadius: BorderRadius.circular(CsRadius.lg),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _find(),
                    decoration: InputDecoration(
                      hintText: l10n.busSearchPlace,
                      prefixIcon: const Icon(CsIcons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: l10n.busSearchPlace,
                              icon: const Icon(CsIcons.arrowRight),
                              onPressed: _find,
                            ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_searchError != null) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(CsSpace.md),
                      child: Text(
                        _searchError!,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (results != null && results.isNotEmpty) ...[
                    const Divider(height: 1),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          for (final p in results)
                            ListTile(
                              dense: true,
                              leading: const Icon(CsIcons.place),
                              title: Text(p.name),
                              subtitle: p.detail.isEmpty
                                  ? null
                                  : Text(
                                      p.detail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              onTap: () => _go(p),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.screen,
            CsSpace.sm,
            CsSpace.screen,
            CsSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.busPickerHint,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
              const SizedBox(height: CsSpace.sm),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_center),
                icon: const Icon(CsIcons.checkCircle),
                label: Text(l10n.busUseThisPlace),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
