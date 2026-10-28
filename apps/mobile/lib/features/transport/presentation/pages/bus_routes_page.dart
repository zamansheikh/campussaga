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
import '../bus_cubit.dart';
import '../bus_format.dart';

/// The student's university bus routes, each with its next bus.
class BusRoutesPage extends StatefulWidget {
  const BusRoutesPage({super.key});

  @override
  State<BusRoutesPage> createState() => _BusRoutesPageState();
}

class _BusRoutesPageState extends State<BusRoutesPage> {
  final _cubit = getIt<BusCubit>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    if (user != null) _cubit.open(user.id);
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider.value(value: _cubit, child: const _RoutesView());
}

class _RoutesView extends StatelessWidget {
  const _RoutesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BusCubit>();
    final s = context.watch<BusCubit>().state;
    final routes = s.routes;
    final canEdit = routes?.canEdit ?? false;
    final now = appNow();

    final Widget body;
    if (routes == null && s.failure != null) {
      body = ListView(
        children: [
          const SizedBox(height: CsSpace.xxl),
          CsEmptyState(
            icon: CsIcons.offline,
            title: busErrorText(l10n, s.failure!),
            actionLabel: l10n.tryAgain,
            onAction: cubit.refresh,
          ),
        ],
      );
    } else if (routes == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (routes.routes.isEmpty) {
      body = ListView(
        children: [
          const SizedBox(height: CsSpace.xxl),
          CsEmptyState(
            icon: CsIcons.bus,
            title: l10n.busRoutesEmptyTitle,
            message: l10n.busRoutesEmptyBody,
            actionLabel: canEdit ? l10n.busAddRoute : null,
            onAction: canEdit ? () => context.push(Routes.busNew) : null,
          ),
        ],
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.screen,
          CsSpace.sm,
          CsSpace.screen,
          CsSpace.xl,
        ),
        children: [
          if (s.offline)
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.sm),
              child: Row(
                children: [
                  Icon(
                    CsIcons.offline,
                    size: 16,
                    color: context.cs.textSecondary,
                  ),
                  const SizedBox(width: CsSpace.xs),
                  Expanded(
                    child: Text(l10n.busOffline, style: context.text.bodySmall),
                  ),
                ],
              ),
            ),
          for (final r in routes.routes) ...[
            _RouteCard(route: r, myStop: s.myStops[r.id], now: now),
            const SizedBox(height: CsSpace.sm),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.busRoutesTitle),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: l10n.busAddRoute,
              onPressed: () => context.push(Routes.busNew),
              icon: const Icon(CsIcons.add),
            ),
        ],
      ),
      body: RefreshIndicator(onRefresh: cubit.refresh, child: body),
    );
  }
}

/// The soonest bus at the student's stop (either way), if they picked one.
BusDeparture? myNext(BusRoute r, String? stopId, DateTime now) {
  if (stopId == null) return null;
  BusDeparture? best;
  for (final d in BusDirection.values) {
    final n = nextDepartures(
      r,
      stopId: stopId,
      direction: d,
      now: now,
      limit: 1,
    ).firstOrNull;
    if (n != null && (best == null || n.at.isBefore(best.at))) best = n;
  }
  return best;
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.myStop,
    required this.now,
  });

  final BusRoute route;
  final String? myStop;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final mine = myNext(route, myStop, now);
    final next = mine ?? nextRouteDeparture(route, now);
    final nextText = next == null
        ? (route.trips.isEmpty ? l10n.busNoTimesYet : l10n.busNoMoreBuses)
        : mine != null
        ? '${l10n.busNextFrom(mine.stop.name)}: ${timeOf(context, mine.at)} · ${whenText(context, mine.at, now)}'
        : '${l10n.busNextAt(timeOf(context, next.at))} · ${whenText(context, next.at, now)}';
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.busRoute(route.id)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: Color(route.argb)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(CsIcons.bus, size: 18, color: Color(route.argb)),
                          const SizedBox(width: CsSpace.xs),
                          Expanded(
                            child: Text(
                              route.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium,
                            ),
                          ),
                          if (!route.active)
                            CsBadge(
                              label: l10n.busHidden,
                              tone: CsBadgeTone.neutral,
                            ),
                        ],
                      ),
                      if (route.span.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${route.span} · ${l10n.busStopsCount(route.stops.length)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: cs.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: CsSpace.xs),
                      Text(
                        nextText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: next == null ? cs.textSecondary : cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(CsIcons.chevronRight, color: cs.textSecondary),
              const SizedBox(width: CsSpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}
