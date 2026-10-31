import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../../app/version/version_gate_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../classes/presentation/class_format.dart';
import '../../data/bus_sharing.dart';
import '../../data/transport_store.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';
import '../bus_live_cubit.dart';
import '../bus_map.dart';
import '../widgets/bus_live_widgets.dart';
import '../widgets/bus_route_map_card.dart';

enum _Edit { route, stops, trips, delete }

/// One route: its live buses (docs/BUS_LIVE.md), the next buses from my
/// stop, the map, the stops with this trip's times, and every departure.
/// Reps get edit buttons, and a setup guide while the route has no stops
/// or times.
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

  /// Live buses, once the feature is on (null until then).
  BusLiveCubit? _live;
  AppLifecycleListener? _lifecycle;

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

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(_live?.close());
    super.dispose();
  }

  /// Starts polling the route's live buses (paused while the app is
  /// hidden).
  BusLiveCubit? _ensureLive() {
    final user = context.read<AuthBloc>().state.user;
    if (_live != null || user == null) return _live;
    final live = _live = BusLiveCubit(
      getIt<BusLiveRepository>(),
      getIt<TransportStore>(),
      routeId: widget.routeId,
      userId: user.id,
    );
    _lifecycle = AppLifecycleListener(
      onHide: live.pause,
      onShow: () {
        live.resume();
        unawaited(live.refresh());
      },
    );
    unawaited(live.start());
    // Sharing ended while this page was closed: thank them now.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _onShare(getIt<BusSharing>().state),
    );
    return live;
  }

  Future<void> _share(BusRoute r, {BusTripDay? trip}) async {
    final choice = await showBusShareSheet(
      context,
      route: r,
      direction: _dir,
      preferred: trip,
    );
    if (choice == null || !mounted) return;
    await startBusSharing(context, getIt<BusSharing>(), r, choice);
    await _live?.refresh();
  }

  Future<void> _stopSharing() async {
    await getIt<BusSharing>().stop();
    await _live?.refresh();
  }

  /// A session of this route ended: thanks, and "How was the trip?".
  Future<void> _onShare(BusShareState s) async {
    final ended = s.ended;
    final live = _live;
    if (ended == null || ended.routeId != widget.routeId || live == null) {
      return;
    }
    getIt<BusSharing>().seenEnded();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final departs = ended.departsMin;
    await showBusThanksSheet(
      context,
      ended: ended,
      onFeedback: departs == null
          ? null
          : (status, crowded) async {
              try {
                await live.feedback(
                  direction: ended.direction,
                  departsMin: departs,
                  day: ended.day,
                  status: status,
                  crowded: crowded,
                );
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.busFeedbackThanks)),
                );
              } on Failure catch (f) {
                messenger.showSnackBar(
                  SnackBar(content: Text(busErrorText(l10n, f))),
                );
              }
            },
    );
    // Asked about this trip: nothing more about this route today.
    if (departs != null) {
      await live.answer(ended.direction, departs, ended.day);
    }
    await live.refresh();
  }

  Future<void> _feedback(
    BusLiveCubit live,
    BusTripDay trip,
    BusTripStatus status,
    bool crowded,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await live.feedback(
        direction: trip.trip.direction,
        departsMin: trip.trip.departsMin,
        day: trip.day,
        status: status,
        crowded: crowded,
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.busFeedbackThanks)));
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(busErrorText(l10n, f))));
    }
  }

  Future<void> _alert(BusLiveCubit live, BusRoute r, BusStop stop) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final current = live.state.alerts[_dir];
    final minutes = await pickBusAlert(context, current: current?.leadMin);
    if (minutes == null || !mounted) return;
    try {
      if (minutes == 0) {
        if (current != null) await live.removeAlert(_dir);
      } else {
        await live.setAlert(stopId: stop.id, direction: _dir, leadMin: minutes);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.busAlertSaved(minutes))),
        );
      }
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(busErrorText(l10n, f))));
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

  /// The live buses, my sharing and "How was the trip?", newest news
  /// first; nothing when there's nothing to say.
  Widget _liveCards(
    BusRoute r,
    BusLiveCubit live,
    BusLiveState ls,
    BusShareState share,
    BusStop? myStop,
  ) => BusTicker(
    builder: (context, now) {
      final cards = <Widget>[];
      final mine = share.sharing(r.id);
      final hasMap = routePoints(r).isNotEmpty;
      VoidCallback? openMap() =>
          hasMap ? () => context.push(Routes.busMap(r.id)) : null;
      if (mine) {
        cards.add(
          share.status == BusShareStatus.starting
              ? const LinearProgressIndicator()
              : BusSharingCard(
                  route: r,
                  share: share,
                  now: now,
                  onStop: _stopSharing,
                  onOpenMap: openMap(),
                ),
        );
      }
      // This way first.
      final runs =
          [
            for (final run in ls.live.runs)
              if (!(mine && run.mine)) run,
          ]..sort(
            (a, b) => (a.direction == _dir ? 0 : 1).compareTo(
              b.direction == _dir ? 0 : 1,
            ),
          );
      for (final run in runs) {
        cards.add(
          BusLiveCard(
            route: r,
            run: run,
            now: now,
            myStopId: myStop?.id,
            onOpenMap: openMap(),
            onJoin: share.active
                ? null
                : () => _share(
                    r,
                    trip: run.departsMin == null
                        ? null
                        : runningTrips(r, now, direction: run.direction)
                              .where((t) => t.trip.departsMin == run.departsMin)
                              .firstOrNull,
                  ),
          ),
        );
      }
      if (!mine && ls.live.runs.isEmpty && ls.loaded) {
        final trip = runningTrips(r, now).firstOrNull;
        if (trip != null) {
          cards.add(
            BusShareInviteCard(
              route: r,
              trip: trip,
              starting: share.status == BusShareStatus.starting,
              onShare: share.active ? () {} : () => _share(r, trip: trip),
            ),
          );
        }
      }
      final recent = myStop == null || mine
          ? null
          : recentTripAt(r, myStop.id, now);
      if (recent != null) {
        final t = recent.trip;
        final asked =
            ls.answered.contains(
              feedbackKey(r.id, t.trip.direction, t.trip.departsMin, t.day),
            ) ||
            ls.answered.contains(feedbackDayKey(r.id, now));
        // Still on its way to my stop: too early to ask.
        final coming = ls.live.runs.any(
          (run) =>
              run.direction == t.trip.direction &&
              run.departsMin == t.trip.departsMin &&
              !run.passed.contains(myStop!.id),
        );
        if (!asked && !coming) {
          cards.add(
            BusFeedbackCard(
              trip: t,
              stop: myStop!,
              at: recent.at,
              onPick: (status, crowded) => _feedback(live, t, status, crowded),
              onDismiss: () =>
                  live.answer(t.trip.direction, t.trip.departsMin, t.day),
            ),
          );
        }
      }
      if (cards.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: CsSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: CsSpace.sm),
              cards[i],
            ],
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final liveOn = context.select(
      (VersionGateCubit g) => g.state.feature('busLive'),
    );
    final live = liveOn ? _ensureLive() : null;
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
        if (live == null) return _page(context, r, s, null, null, null);
        return BlocConsumer<BusSharing, BusShareState>(
          bloc: getIt<BusSharing>(),
          listenWhen: (a, b) => b.ended != null && a.ended != b.ended,
          listener: (_, share) => unawaited(_onShare(share)),
          builder: (context, share) => BlocBuilder<BusLiveCubit, BusLiveState>(
            bloc: live,
            builder: (context, ls) => _page(context, r, s, live, ls, share),
          ),
        );
      },
    );
  }

  Widget _page(
    BuildContext context,
    BusRoute r,
    BusState s,
    BusLiveCubit? live,
    BusLiveState? ls,
    BusShareState? share,
  ) {
    final l10n = AppLocalizations.of(context);
    final canEdit = s.routes?.canEdit ?? false;
    final now = appNow();
    final myStopId = s.myStops[r.id];
    final myStop = r.stops.where((x) => x.id == myStopId).firstOrNull;
    final nextTrip = myStop == null
        ? null
        : nextDepartures(
            r,
            stopId: myStop.id,
            direction: _dir,
            now: now,
            limit: 1,
          ).firstOrNull?.trip;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          if (live != null && share != null && !share.active && r.active)
            IconButton(
              tooltip: l10n.busShareOn,
              onPressed: () => _share(r),
              icon: const Icon(CsIcons.live),
            ),
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
            if (live != null && ls != null && share != null)
              _liveCards(r, live, ls, share, myStop),
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
              _SetupCard(route: r, onStops: _editStops, onTimes: _editTrips),
              const SizedBox(height: CsSpace.md),
            ],
            _MyStopCard(
              route: r,
              stop: myStop,
              direction: _dir,
              now: now,
              onPick: () => _pickStop(r, myStopId),
              notes: nextTrip == null
                  ? const []
                  : ls?.insight(nextTrip)?.notes ?? const [],
              alert: ls?.alerts[_dir],
              onAlert: live == null || myStop == null
                  ? null
                  : () => _alert(live, r, myStop),
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
              insight: ls?.insight,
            ),
          ],
        ),
      ),
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
    this.notes = const [],
    this.alert,
    this.onAlert,
  });

  final BusRoute route;
  final BusStop? stop;
  final BusDirection direction;
  final DateTime now;
  final VoidCallback onPick;

  /// What riders say about the next bus ("Usually on time").
  final List<BusTripNote> notes;

  /// "Tell me when the bus is near" (null: live buses are off).
  final BusAlert? alert;
  final VoidCallback? onAlert;

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
            if (notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xs),
                child: Text(
                  [for (final n in notes) busNoteText(l10n, n)].join(' · '),
                  style: context.text.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onAlert != null)
                Flexible(
                  child: TextButton.icon(
                    onPressed: onAlert,
                    icon: Icon(
                      alert == null ? CsIcons.bell : CsIcons.bellActive,
                      size: 18,
                    ),
                    label: Text(
                      alert == null
                          ? l10n.busAlert
                          : l10n.busAlertOn(alert!.leadMin),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Flexible(
                child: TextButton(
                  onPressed: onPick,
                  child: Text(
                    l10n.busChangeStop,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
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
    this.insight,
  });

  final BusRoute route;
  final BusDirection direction;
  final VoidCallback? onEdit;

  /// What riders say about a trip (null: live buses are off).
  final BusTripInsight? Function(BusTrip)? insight;

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
                for (final n
                    in insight?.call(t)?.notes ?? const <BusTripNote>[])
                  busNoteText(l10n, n),
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

/// The route's driver: name and number, and a round call button (opens
/// the dialer); the whole card calls too. The button stays one small size
/// whatever the language, so the number never wraps.
class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.route});

  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final name = route.driverName;
    final call = name.isEmpty ? l10n.busCallDriver : l10n.busCallName(name);
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => callPhone(route.driverPhone),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CsSpace.md, 12, 12, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(route.argb).withValues(alpha: 0.15),
                child: Icon(CsIcons.bus, color: Color(route.argb)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? l10n.busDriver : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      name.isEmpty
                          ? route.driverPhone
                          : '${l10n.busDriver} · ${route.driverPhone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CsSpace.sm),
              IconButton.filled(
                tooltip: call,
                onPressed: () => callPhone(route.driverPhone),
                icon: const Icon(CsIcons.call, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
