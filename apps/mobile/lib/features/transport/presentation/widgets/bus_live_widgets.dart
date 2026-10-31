import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/clock.dart';
import '../../../classes/presentation/class_format.dart';
import '../../data/bus_sharing.dart';
import '../../data/my_location.dart';
import '../bus_format.dart';

/// Live buses on the route page: a live bus, the invite to share one, my
/// own sharing, and "How was the trip?" (docs/BUS_LIVE.md §4).

/// "To campus · 7:30 AM" (or "· Not on the timetable").
String busTripText(BuildContext context, BusDirection d, int? departsMin) {
  final l10n = AppLocalizations.of(context);
  final way = d == BusDirection.toCampus
      ? l10n.busToCampus
      : l10n.busFromCampus;
  return '$way · ${departsMin == null ? l10n.busOffTimetable : clockText(context, departsMin)}';
}

String busNoteText(AppLocalizations l10n, BusTripNote n) => switch (n.kind) {
  BusTripNoteKind.usuallyOnTime => l10n.busNoteOnTime,
  BusTripNoteKind.oftenLate =>
    n.minutes == null ? l10n.busNoteLate : l10n.busNoteLateMin(n.minutes!),
  BusTripNoteKind.oftenCrowded => l10n.busNoteCrowded,
  BusTripNoteKind.sometimesNoShow => l10n.busNoteNoShow,
};

/// "At Mirpur 10", "On the way to Mirpur 11", "Off the usual route".
String busPlaceText(BuildContext context, BusRoute route, BusRun run) {
  final l10n = AppLocalizations.of(context);
  if (!run.onRoute) return l10n.busLiveOffRoute;
  final place = busPlace(route, run);
  if (place != null && place.at) return l10n.busLiveAt(place.stop.name);
  final next = route.stops.where((s) => s.id == run.nextStopId).firstOrNull;
  if (next != null) return l10n.busLiveHeading(next.name);
  if (place != null) return l10n.busLiveNear(place.stop.name);
  return l10n.busLiveOnTheWay;
}

/// "4 min late", "On time", "2 min early" (null: unknown).
String? busDelayText(AppLocalizations l10n, int? delayMin) {
  if (delayMin == null) return null;
  if (delayMin >= 2) return l10n.busLiveLate(delayMin);
  if (delayMin <= -2) return l10n.busLiveEarly(-delayMin);
  return l10n.busLiveOnTime;
}

/// "10 s ago", "2 min ago".
String busAgoText(AppLocalizations l10n, DateTime at, DateTime now) {
  final s = now.difference(at).inSeconds;
  if (s < 60) return l10n.busLiveSecondsAgo(s < 1 ? 1 : s);
  return l10n.busLiveMinutesAgo(s ~/ 60);
}

/// Minutes until [run] reaches [stopId] (0: now); null when it won't or
/// it isn't known.
int? busEtaMinutes(BusRun run, String stopId, DateTime now) {
  final at = run.etas[stopId];
  if (at == null) return null;
  final m = (at.difference(now).inSeconds / 60).round();
  return m < 0 ? 0 : m;
}

/// A live bus is stale once nobody has sent a point for this long; it's
/// greyed out until the server drops it.
const busStaleAfter = Duration(seconds: 90);

/// The card's frame: one look for every live card on the page.
class _LiveFrame extends StatelessWidget {
  const _LiveFrame({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(
          color: accent?.withValues(alpha: 0.55) ?? cs.border,
          width: accent == null ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.md,
          12,
          CsSpace.md,
          CsSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    );
  }
}

class _BusAvatar extends StatelessWidget {
  const _BusAvatar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: color.withValues(alpha: 0.15),
    child: Icon(CsIcons.bus, color: color),
  );
}

/// A bus on its way now: where it is, how late, when it reaches my stop.
class BusLiveCard extends StatelessWidget {
  const BusLiveCard({
    super.key,
    required this.route,
    required this.run,
    required this.now,
    this.myStopId,
    this.onOpenMap,
    this.onJoin,
  });

  final BusRoute route;
  final BusRun run;
  final DateTime now;
  final String? myStopId;
  final VoidCallback? onOpenMap;

  /// "I'm on this bus too": more riders sharing, a truer position.
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final color = Color(route.argb);
    final stale = now.difference(run.updatedAt) > busStaleAfter;
    final myStop = route.stops.where((s) => s.id == myStopId).firstOrNull;
    final eta = myStop == null ? null : busEtaMinutes(run, myStop.id, now);
    final passed = myStop != null && run.passed.contains(myStop.id);
    final facts = [
      l10n.busLiveSharing(run.riders),
      ?busDelayText(l10n, run.delayMin),
    ];
    return _LiveFrame(
      accent: stale ? null : color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: CsLiveLabel(
                  label: l10n.busLive,
                  detail: busTripText(context, run.direction, run.departsMin),
                  pulse: run.updatedAt,
                ),
              ),
              const SizedBox(width: CsSpace.sm),
              Text(
                busAgoText(l10n, run.updatedAt, now),
                style: context.text.labelSmall?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BusAvatar(color: stale ? cs.textSecondary : color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      busPlaceText(context, route, run),
                      style: context.text.titleMedium,
                    ),
                    Text(
                      facts.join(' · '),
                      style: context.text.bodySmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (run.fraction case final f?) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: f,
                minHeight: 6,
                color: stale ? cs.textSecondary : color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ],
          if (myStop != null && (eta != null || passed)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(CsRadius.md),
              ),
              child: Row(
                children: [
                  Icon(CsIcons.place, size: 18, color: cs.onPrimaryContainer),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: Text(
                      passed
                          ? l10n.busLivePassed(myStop.name)
                          : eta == 0
                          ? l10n.busLiveEtaNow(myStop.name)
                          : l10n.busLiveEta(myStop.name, eta!),
                      style: context.text.titleSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onOpenMap != null || onJoin != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onOpenMap != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenMap,
                      icon: const Icon(CsIcons.map, size: 18),
                      label: Text(l10n.busLiveMap),
                    ),
                  ),
                if (onOpenMap != null && onJoin != null)
                  const SizedBox(width: CsSpace.sm),
                if (onJoin != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(CsIcons.live, size: 18),
                      label: Text(
                        l10n.busShareJoin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// No bus is live but one should be running: ask riders to share it.
class BusShareInviteCard extends StatelessWidget {
  const BusShareInviteCard({
    super.key,
    required this.route,
    required this.trip,
    required this.onShare,
    this.starting = false,
  });

  final BusRoute route;
  final BusTripDay trip;
  final VoidCallback onShare;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return _LiveFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _BusAvatar(color: Color(route.argb)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.busShareAsk(
                        clockText(context, trip.trip.departsMin),
                      ),
                      style: context.text.titleMedium,
                    ),
                    Text(
                      l10n.busShareAskBody,
                      style: context.text.bodySmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: starting ? null : onShare,
            icon: starting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CsIcons.live, size: 18),
            label: Text(starting ? l10n.busSharingStarting : l10n.busShareImOn),
          ),
        ],
      ),
    );
  }
}

/// I'm sharing this route's bus.
class BusSharingCard extends StatelessWidget {
  const BusSharingCard({
    super.key,
    required this.route,
    required this.share,
    required this.now,
    required this.onStop,
    this.onOpenMap,
  });

  final BusRoute route;
  final BusShareState share;
  final DateTime now;
  final VoidCallback onStop;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final sent = share.lastSentAt ?? share.startedAt;
    final dir = share.direction;
    return _LiveFrame(
      accent: Color(route.argb),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: CsLiveLabel(
                  label: l10n.busLive,
                  detail: dir == null
                      ? null
                      : busTripText(context, dir, share.departsMin),
                  pulse: share.lastSentAt,
                ),
              ),
              if (sent != null && !share.offline) ...[
                const SizedBox(width: CsSpace.sm),
                Text(
                  busAgoText(l10n, sent, now),
                  style: context.text.labelSmall?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BusAvatar(color: Color(route.argb)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.busSharingTitle, style: context.text.titleMedium),
                    Text(
                      share.offline
                          ? l10n.busSharingOffline
                          : l10n.busSharingOthers(
                              share.riders > 1 ? share.riders - 1 : 0,
                            ),
                      style: context.text.bodySmall?.copyWith(
                        color: share.offline ? cs.error : cs.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onOpenMap != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(CsIcons.map, size: 18),
                    label: Text(l10n.busLiveMap),
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                  ),
                  onPressed: onStop,
                  icon: const Icon(CsIcons.stopSharing, size: 18),
                  label: Text(l10n.busSharingStop),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// On time · Late · Didn't come, and "It was crowded": one tap sends it.
class BusFeedbackButtons extends StatefulWidget {
  const BusFeedbackButtons({
    super.key,
    required this.onPick,
    this.noShow = true,
  });

  final Future<void> Function(BusTripStatus status, bool crowded) onPick;

  /// Offer "Didn't come" (not to someone who just rode it).
  final bool noShow;

  @override
  State<BusFeedbackButtons> createState() => _BusFeedbackButtonsState();
}

class _BusFeedbackButtonsState extends State<BusFeedbackButtons> {
  bool _crowded = false;
  BusTripStatus? _sending;

  Future<void> _pick(BusTripStatus s) async {
    setState(() => _sending = s);
    try {
      await widget.onPick(s, _crowded);
    } finally {
      if (mounted) setState(() => _sending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    Widget button(BusTripStatus s, String label) => Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        onPressed: _sending == null ? () => _pick(s) : null,
        child: _sending == s
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            button(BusTripStatus.onTime, l10n.busFeedbackOnTime),
            const SizedBox(width: CsSpace.sm),
            button(BusTripStatus.late, l10n.busFeedbackLate),
            if (widget.noShow) ...[
              const SizedBox(width: CsSpace.sm),
              button(BusTripStatus.noShow, l10n.busFeedbackNoShow),
            ],
          ],
        ),
        const SizedBox(height: CsSpace.xs),
        InkWell(
          borderRadius: BorderRadius.circular(CsRadius.md),
          onTap: _sending == null
              ? () => setState(() => _crowded = !_crowded)
              : null,
          child: Row(
            children: [
              Checkbox(
                value: _crowded,
                onChanged: _sending == null
                    ? (v) => setState(() => _crowded = v ?? false)
                    : null,
              ),
              Icon(CsIcons.crowded, size: 18, color: cs.textSecondary),
              const SizedBox(width: CsSpace.xs),
              Text(l10n.busFeedbackCrowded, style: context.text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// "How was the 7:30 bus?" for the latest trip past my stop.
class BusFeedbackCard extends StatelessWidget {
  const BusFeedbackCard({
    super.key,
    required this.trip,
    required this.stop,
    required this.at,
    required this.onPick,
    required this.onDismiss,
  });

  final BusTripDay trip;
  final BusStop stop;
  final DateTime at;
  final Future<void> Function(BusTripStatus status, bool crowded) onPick;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final t = trip.trip;
    return _LiveFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.busFeedbackTitle(clockText(context, t.departsMin)),
                      style: context.text.titleMedium,
                    ),
                    Text(
                      '${t.direction == BusDirection.toCampus ? l10n.busToCampus : l10n.busFromCampus}'
                      ' · ${l10n.busFeedbackAt(stop.name, timeOf(context, at))}',
                      style: context.text.bodySmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.busFeedbackNotNow,
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: Icon(CsIcons.close, size: 20, color: cs.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.sm),
          BusFeedbackButtons(onPick: onPick),
        ],
      ),
    );
  }
}

/// What the student picked in the share sheet.
typedef BusShareChoice = ({
  BusDirection direction,
  int? departsMin,
  DateTime day,
});

/// Which bus, what is shared and who sees it (Play's prominent
/// disclosure), then Start. Null when closed.
Future<BusShareChoice?> showBusShareSheet(
  BuildContext context, {
  required BusRoute route,
  required BusDirection direction,
  BusTripDay? preferred,
}) {
  final now = appNow();
  final trips = shareableTrips(route, now);
  final options = <BusShareChoice>[
    for (final t in trips)
      (direction: t.trip.direction, departsMin: t.trip.departsMin, day: t.day),
    (
      direction: direction,
      departsMin: null,
      day: DateTime(now.year, now.month, now.day),
    ),
  ];
  var picked = preferred == null
      ? options.first
      : options.firstWhere(
          (o) =>
              o.direction == preferred.trip.direction &&
              o.departsMin == preferred.trip.departsMin,
          orElse: () => options.first,
        );
  return showModalBottomSheet<BusShareChoice>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cs = sheet.cs;
      Widget fact(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: sheet.text.bodyMedium)),
          ],
        ),
      );
      return StatefulBuilder(
        builder: (sheet, setSheet) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.screen,
            0,
            CsSpace.screen,
            CsSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.busShareOn, style: sheet.text.titleLarge),
              Text(
                route.name,
                style: sheet.text.bodyMedium?.copyWith(color: cs.textSecondary),
              ),
              const SizedBox(height: CsSpace.md),
              Text(l10n.busShareWhich, style: sheet.text.titleSmall),
              const SizedBox(height: CsSpace.sm),
              Wrap(
                spacing: CsSpace.sm,
                runSpacing: CsSpace.sm,
                children: [
                  for (final o in options)
                    ChoiceChip(
                      label: Text(
                        o.departsMin == null
                            ? '${l10n.busShareOther} · ${o.direction == BusDirection.toCampus ? l10n.busToCampus : l10n.busFromCampus}'
                            : busTripText(sheet, o.direction, o.departsMin),
                      ),
                      selected: o == picked,
                      onSelected: (_) => setSheet(() => picked = o),
                    ),
                ],
              ),
              const SizedBox(height: CsSpace.lg),
              fact(CsIcons.live, l10n.busShareWhat),
              fact(CsIcons.privacy, l10n.busShareWho),
              fact(CsIcons.time, l10n.busShareEnds),
              const SizedBox(height: CsSpace.sm),
              FilledButton.icon(
                onPressed: () => Navigator.of(sheet).pop(picked),
                icon: const Icon(CsIcons.live, size: 18),
                label: Text(l10n.busShareStart),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Starts sharing [choice] and explains anything in the way.
Future<void> startBusSharing(
  BuildContext context,
  BusSharing sharing,
  BusRoute route,
  BusShareChoice choice,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final problem = await sharing.start(
    route,
    direction: choice.direction,
    departsMin: choice.departsMin,
    day: choice.day,
    notice: (
      title: l10n.busShareNoticeTitle(route.name),
      text: l10n.busShareNoticeText,
      channel: l10n.busShareChannel,
    ),
  );
  switch (problem) {
    case null:
      return;
    case BusShareNoLocation(:final problem):
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            problem == LocationProblem.serviceOff
                ? l10n.busLocationServiceOff
                : l10n.busLocationDenied,
          ),
          action: SnackBarAction(
            label: l10n.busOpenSettings,
            onPressed: () => MyLocation.instance.openSettings(problem),
          ),
        ),
      );
    case BusShareRefused(:final failure):
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (failure.code) {
            'NOT_ON_ROUTE' => l10n.busShareNotOnRoute,
            'TRIP_NOT_RUNNING' => l10n.busShareNotRunning,
            'SHARE_LIMIT' => l10n.busShareLimit,
            _ => busErrorText(l10n, failure),
          }),
        ),
      );
  }
}

/// After sharing: thanks, why it stopped, and "How was the trip?".
Future<void> showBusThanksSheet(
  BuildContext context, {
  required BusShareEnded ended,
  Future<void> Function(BusTripStatus status, bool crowded)? onFeedback,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    final cs = sheet.cs;
    final thanks = ended.thanks;
    final why = switch (ended.reason) {
      BusShareEnd.arrived => l10n.busEndedArrived,
      BusShareEnd.offRoute => l10n.busEndedOffRoute,
      BusShareEnd.expired => l10n.busEndedExpired,
      BusShareEnd.replaced => l10n.busEndedReplaced,
      BusShareEnd.stopped => null,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        CsSpace.screen,
        0,
        CsSpace.screen,
        CsSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Icon(CsIcons.thanks, size: 30, color: cs.primary),
            ),
          ),
          const SizedBox(height: CsSpace.sm),
          Text(
            l10n.busThanksTitle,
            textAlign: TextAlign.center,
            style: sheet.text.titleLarge,
          ),
          const SizedBox(height: CsSpace.xs),
          Text(
            [
              l10n.busThanksHelped(thanks?.helped ?? 0),
              if (thanks != null && thanks.trips > 0)
                l10n.busThanksTrips(thanks.trips),
            ].join(' '),
            textAlign: TextAlign.center,
            style: sheet.text.bodyMedium,
          ),
          if (why != null) ...[
            const SizedBox(height: CsSpace.xs),
            Text(
              why,
              textAlign: TextAlign.center,
              style: sheet.text.bodySmall?.copyWith(color: cs.textSecondary),
            ),
          ],
          if (onFeedback != null && ended.departsMin != null) ...[
            const SizedBox(height: CsSpace.lg),
            Text(
              l10n.busFeedbackTitle(clockText(sheet, ended.departsMin!)),
              style: sheet.text.titleSmall,
            ),
            const SizedBox(height: CsSpace.sm),
            BusFeedbackButtons(
              noShow: false,
              onPick: (s, crowded) async {
                await onFeedback(s, crowded);
                if (sheet.mounted) Navigator.of(sheet).pop();
              },
            ),
          ],
          const SizedBox(height: CsSpace.sm),
          TextButton(
            onPressed: () => Navigator.of(sheet).pop(),
            child: Text(
              onFeedback != null && ended.departsMin != null
                  ? l10n.busFeedbackNotNow
                  : l10n.gotIt,
            ),
          ),
        ],
      ),
    );
  },
);

/// "Tell me when a live bus is… 5 / 10 / 15 min from my stop, or Off".
/// Returns the minutes, 0 for off, or null when closed.
Future<int?> pickBusAlert(BuildContext context, {int? current}) {
  final l10n = AppLocalizations.of(context);
  return CsOptionSheet.show<int>(
    context: context,
    title: l10n.busAlertTitle,
    message: l10n.busAlertHint,
    selected: current ?? 0,
    options: [
      for (final m in BusAlert.leads)
        CsOption(m, l10n.busAlertMinutes(m), icon: CsIcons.bell),
      CsOption(0, l10n.busAlertOff, icon: CsIcons.close),
    ],
  );
}

/// A short-lived "now" that ticks while live data is shown (for "10 s
/// ago" and ETAs between polls).
class BusTicker extends StatefulWidget {
  const BusTicker({super.key, required this.builder, this.every});

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration? every;

  @override
  State<BusTicker> createState() => _BusTickerState();
}

class _BusTickerState extends State<BusTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      widget.every ?? const Duration(seconds: 5),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, appNow());
}
