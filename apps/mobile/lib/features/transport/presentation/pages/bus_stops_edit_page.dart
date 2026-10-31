import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/di.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';
import '../bus_map.dart';
import 'stop_location_page.dart';

/// A route's stops, from the far end to campus. Reps type stops one after
/// another (or paste a notice's list), give the minutes from the stop
/// before, and place each stop on the map. The way back is the same
/// journey reversed unless they switch that off. Pops with true once saved.
class BusStopsEditPage extends StatefulWidget {
  const BusStopsEditPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<BusStopsEditPage> createState() => _BusStopsEditPageState();
}

/// One row. Times live as legs (minutes from the timed stop before) and are
/// turned back into minutes from the start when saving.
class _Item {
  _Item({required this.key, required this.stop, this.toLeg, this.backLeg});

  final int key; // stable list key: new stops have no id yet
  BusStop stop; // name, landmark and location (its times are not used)
  int? toLeg;
  int? backLeg; // way back, from the timed stop after it (towards campus)
}

class _BusStopsEditPageState extends State<BusStopsEditPage> {
  final _cubit = getIt<BusCubit>();
  final _quick = TextEditingController();
  final _quickFocus = FocusNode();
  final _scroll = ScrollController();
  late final BusRoute? _route = _cubit.state.route(widget.routeId);
  late final List<_Item> _items;
  late bool _mirror;
  late int _nextKey;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final stops = _route?.stops ?? const <BusStop>[];
    final toLegs = legsFromOffsets([for (final s in stops) s.toCampusMin]);
    // Way-back legs run from campus, so work them out on the reversed list.
    final backLegs = legsFromOffsets([
      for (final s in stops.reversed) s.fromCampusMin,
    ]).reversed.toList();
    _items = [
      for (final (i, s) in stops.indexed)
        _Item(key: i, stop: s, toLeg: toLegs[i], backLeg: backLegs[i]),
    ];
    _nextKey = _items.length;
    _mirror = isMirrored(stops);
  }

  @override
  void dispose() {
    _quick.dispose();
    _quickFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Color get _color => Color(_route?.argb ?? 0xFF0F766E);

  void _change(VoidCallback f) => setState(() {
    f();
    _dirty = true;
  });

  List<BusStop> _result() => stopsWithLegs(
    [for (final i in _items) i.stop],
    toLegs: [for (final i in _items) i.toLeg],
    backLegs: _mirror ? null : [for (final i in _items.reversed) i.backLeg],
  );

  int? get _total {
    if (_items.length < 2) return null;
    return offsetsFromLegs([for (final i in _items) i.toLeg]).last;
  }

  // ---- adding ---------------------------------------------------------------

  bool _roomFor(int n) {
    if (_items.length + n <= maxBusStops) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).busTooManyStops(maxBusStops),
        ),
      ),
    );
    return false;
  }

  void _add(List<StopDraft> drafts) {
    if (drafts.isEmpty || !_roomFor(drafts.length)) return;
    _change(() {
      for (final d in drafts) {
        _items.add(
          _Item(
            key: _nextKey++,
            stop: BusStop(id: '', name: d.name, landmark: d.landmark),
          ),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _quickAdd() {
    final name = _quick.text.trim();
    if (name.isEmpty) return;
    final draft = parseStopList(name);
    // One typed name stays one stop, even with a comma in it.
    _add(draft.length > 1 ? draft : [StopDraft(_clip(name), '')]);
    _quick.clear();
    _quickFocus.requestFocus();
  }

  static String _clip(String s) =>
      s.length <= maxStopName ? s : s.substring(0, maxStopName);

  Future<void> _paste() async {
    final drafts = await showModalBottomSheet<List<StopDraft>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PasteSheet(),
    );
    if (drafts != null) _add(drafts);
  }

  // ---- editing --------------------------------------------------------------

  void _remove(_Item item) {
    final l10n = AppLocalizations.of(context);
    final at = _items.indexOf(item);
    if (at < 0) return;
    _change(() => _items.removeAt(at));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.busStopRemoved(item.stop.name)),
          action: SnackBarAction(
            label: l10n.busUndo,
            onPressed: () {
              if (!mounted) return;
              _change(() => _items.insert(at.clamp(0, _items.length), item));
            },
          ),
        ),
      );
  }

  /// The name of the nearest timed stop before [i] (way there) or after it
  /// (way back), for "minutes from …".
  String _fromName(int i, {required bool back}) {
    if (back) {
      for (var j = i + 1; j < _items.length; j++) {
        if (j == _items.length - 1 || _items[j].backLeg != null) {
          return _items[j].stop.name;
        }
      }
      return _items.last.stop.name;
    }
    for (var j = i - 1; j >= 0; j--) {
      if (j == 0 || _items[j].toLeg != null) return _items[j].stop.name;
    }
    return _items.first.stop.name;
  }

  LatLng? _nearestPlaced(int i) {
    for (var d = 1; d < _items.length; d++) {
      for (final j in [i - d, i + d]) {
        if (j >= 0 && j < _items.length) {
          final p = stopPoint(_items[j].stop);
          if (p != null) return p;
        }
      }
    }
    return null;
  }

  Future<void> _edit(_Item item) async {
    final i = _items.indexOf(item);
    final res = await showModalBottomSheet<_StopEdit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _StopSheet(
        item: item,
        isFirst: i == 0,
        isLast: i == _items.length - 1 && _items.length > 1,
        mirror: _mirror,
        fromName: i == 0 ? '' : _fromName(i, back: false),
        backFromName: i == _items.length - 1 ? '' : _fromName(i, back: true),
        color: _color,
        near: _nearestPlaced(i),
        others: [
          for (final x in _items)
            if (x != item) ?stopPoint(x.stop),
        ],
      ),
    );
    if (res == null || !mounted) return;
    if (res.remove) {
      _remove(item);
      return;
    }
    _change(() {
      item
        ..stop = res.stop
        ..toLeg = res.toLeg
        ..backLeg = res.backLeg;
    });
  }

  void _setMirror(bool on) {
    _change(() {
      if (!on) {
        // Start the separate way back from the reversed times.
        final back = mirroredFromCampus(
          offsetsFromLegs([for (final i in _items) i.toLeg]),
        );
        final legs = legsFromOffsets(back.reversed.toList()).reversed.toList();
        for (final (k, i) in _items.indexed) {
          i.backLeg = legs[k];
        }
      }
      _mirror = on;
    });
  }

  // ---- saving ---------------------------------------------------------------

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final stops = _result();
    final tooLong = stops.any(
      (s) => (s.toCampusMin ?? 0) > 600 || (s.fromCampusMin ?? 0) > 600,
    );
    if (tooLong) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.busTripTooLong)));
      return;
    }
    setState(() => _saving = true);
    try {
      await _cubit.setStops(widget.routeId, stops);
      if (!mounted) return;
      _dirty = false;
      messenger.showSnackBar(SnackBar(content: Text(l10n.busSaved)));
      context.pop(true);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(busErrorText(l10n, f))));
    }
  }

  Future<void> _maybeLeave() async {
    final leave = await confirmDiscard(context);
    if (leave && mounted) context.pop();
  }

  // ---- view -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybeLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.busEditStops),
          actions: [
            CsBarButton(
              label: l10n.busSave,
              busy: _saving,
              onPressed: _dirty ? _save : null,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_saving) const LinearProgressIndicator(),
            Expanded(
              child: _items.isEmpty
                  ? _Empty(onPaste: _paste)
                  : ReorderableListView.builder(
                      scrollController: _scroll,
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(bottom: CsSpace.lg),
                      header: _Header(
                        total: _total,
                        mirror: _mirror,
                        onMirror: _setMirror,
                      ),
                      itemCount: _items.length,
                      onReorderItem: (from, to) => _change(
                        () => _items.insert(to, _items.removeAt(from)),
                      ),
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        return Dismissible(
                          key: ValueKey(item.key),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: cs.error,
                            alignment: AlignmentDirectional.centerEnd,
                            padding: const EdgeInsets.symmetric(
                              horizontal: CsSpace.lg,
                            ),
                            child: Icon(CsIcons.delete, color: cs.onError),
                          ),
                          onDismissed: (_) => _remove(item),
                          child: _StopRow(
                            index: i,
                            count: _items.length,
                            item: item,
                            mirror: _mirror,
                            color: _color,
                            onTap: () => _edit(item),
                          ),
                        );
                      },
                    ),
            ),
            _QuickAdd(
              controller: _quick,
              focus: _quickFocus,
              onAdd: _quickAdd,
              onPaste: _paste,
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks before throwing away unsaved edits; true to leave.
Future<bool> confirmDiscard(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(l10n.busDiscardTitle),
      content: Text(l10n.busDiscardBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(d).pop(false),
          child: Text(l10n.busKeepEditing),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: d.cs.error),
          onPressed: () => Navigator.of(d).pop(true),
          child: Text(l10n.busDiscard),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onPaste});

  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(CsSpace.screen),
      children: [
        const SizedBox(height: CsSpace.xl),
        CsEmptyState(
          icon: CsIcons.place,
          title: l10n.busNoStops,
          message: l10n.busStopsHint,
        ),
        const SizedBox(height: CsSpace.md),
        Center(
          child: OutlinedButton.icon(
            onPressed: onPaste,
            icon: const Icon(CsIcons.paste),
            label: Text(l10n.busPasteList),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.mirror,
    required this.onMirror,
  });

  final int? total;
  final bool mirror;
  final ValueChanged<bool> onMirror;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CsSpace.screen,
        CsSpace.sm,
        CsSpace.screen,
        CsSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.busStopsHint,
                  style: context.text.bodySmall?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
              ),
              if (total != null) ...[
                const SizedBox(width: CsSpace.sm),
                CsBadge(
                  label: l10n.busTotalTrip(total!),
                  tone: CsBadgeTone.primary,
                ),
              ],
            ],
          ),
          const SizedBox(height: CsSpace.sm),
          Material(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(CsRadius.md),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              value: mirror,
              onChanged: onMirror,
              title: Text(l10n.busSameWayBack),
              subtitle: Text(l10n.busSameWayBackHint),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.index,
    required this.count,
    required this.item,
    required this.mirror,
    required this.color,
    required this.onTap,
  });

  final int index;
  final int count;
  final _Item item;
  final bool mirror;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final s = item.stop;
    String leg(int? v) => v == null ? l10n.busNoTime : l10n.busLegValue(v);
    final times = [
      if (index == 0) l10n.busStart else leg(item.toLeg),
      if (!mirror && index < count - 1)
        '${l10n.busFromCampus}: ${leg(item.backLeg)}',
    ].join(' · ');
    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CsSpace.screen, 10, 4, 10),
          child: Row(
            children: [
              StopDot(number: index + 1, color: color, big: true),
              const SizedBox(width: CsSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: context.text.bodyLarge),
                    if (s.landmark.isNotEmpty)
                      Text(
                        s.landmark,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      times,
                      style: context.text.labelMedium?.copyWith(
                        color: item.toLeg == null && index > 0
                            ? cs.textSecondary
                            : cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: s.hasLocation
                    ? l10n.busLocationSet
                    : l10n.busLocationNone,
                child: Icon(
                  s.hasLocation ? CsIcons.placeFill : CsIcons.place,
                  size: 20,
                  color: s.hasLocation ? color : cs.textSecondary,
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(CsIcons.dragHandle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The add bar under the list: type a name, press Enter, type the next.
class _QuickAdd extends StatelessWidget {
  const _QuickAdd({
    required this.controller,
    required this.focus,
    required this.onAdd,
    required this.onPaste,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onAdd;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Material(
      color: cs.surface,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            4,
            CsSpace.sm,
            CsSpace.sm,
            CsSpace.sm,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.busPasteList,
                onPressed: onPaste,
                icon: const Icon(CsIcons.paste),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focus,
                  maxLength: maxStopName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    hintText: l10n.busQuickAddHint,
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: CsSpace.xs),
              IconButton.filled(
                tooltip: l10n.busAddStop,
                onPressed: onAdd,
                icon: const Icon(CsIcons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasteSheet extends StatefulWidget {
  const _PasteSheet();

  @override
  State<_PasteSheet> createState() => _PasteSheetState();
}

class _PasteSheetState extends State<_PasteSheet> {
  final _text = TextEditingController();
  List<StopDraft> _drafts = const [];

  @override
  void initState() {
    super.initState();
    _text.addListener(
      () => setState(() => _drafts = parseStopList(_text.text)),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _fromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text;
    if (t != null && t.isNotEmpty) _text.text = t;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.busPasteTitle,
                    style: context.text.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _fromClipboard,
                  icon: const Icon(CsIcons.paste),
                  label: Text(l10n.busPasteFromClipboard),
                ),
              ],
            ),
            Text(
              l10n.busPasteBody,
              style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: CsSpace.sm),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: CsSpace.sm),
            if (_drafts.isEmpty)
              Text(
                l10n.busPasteNone,
                style: context.text.bodySmall?.copyWith(
                  color: cs.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (i, d) in _drafts.take(30).indexed)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${i + 1}. $d'),
                    ),
                  if (_drafts.length > 30)
                    Chip(label: Text('+${_drafts.length - 30}')),
                ],
              ),
            const SizedBox(height: CsSpace.md),
            FilledButton(
              onPressed: _drafts.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_drafts),
              child: Text(l10n.busPasteAdd(_drafts.length)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopEdit {
  const _StopEdit({required this.stop, this.toLeg, this.backLeg})
    : remove = false;

  const _StopEdit.remove()
    : stop = const BusStop(id: '', name: ''),
      toLeg = null,
      backLeg = null,
      remove = true;

  final BusStop stop;
  final int? toLeg;
  final int? backLeg;
  final bool remove;
}

class _StopSheet extends StatefulWidget {
  const _StopSheet({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.mirror,
    required this.fromName,
    required this.backFromName,
    required this.color,
    required this.near,
    required this.others,
  });

  final _Item item;
  final bool isFirst;
  final bool isLast;
  final bool mirror;
  final String fromName;
  final String backFromName;
  final Color color;
  final LatLng? near;
  final List<LatLng> others;

  @override
  State<_StopSheet> createState() => _StopSheetState();
}

class _StopSheetState extends State<_StopSheet> {
  late final _name = TextEditingController(text: widget.item.stop.name);
  late final _landmark = TextEditingController(text: widget.item.stop.landmark);
  late final _to = TextEditingController(
    text: widget.item.toLeg?.toString() ?? '',
  );
  late final _back = TextEditingController(
    text: widget.item.backLeg?.toString() ?? '',
  );
  late LatLng? _place = stopPoint(widget.item.stop);
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _landmark.dispose();
    _to.dispose();
    _back.dispose();
    super.dispose();
  }

  int? _min(TextEditingController c) =>
      int.tryParse(c.text.trim())?.clamp(0, 600);

  Future<void> _pick() async {
    final p = await StopLocationPage.open(
      context,
      stopName: _name.text.trim().isEmpty
          ? widget.item.stop.name
          : _name.text.trim(),
      color: widget.color,
      initial: _place,
      near: widget.near,
      others: widget.others,
    );
    if (p != null && mounted) setState(() => _place = p);
  }

  void _done() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = AppLocalizations.of(context).busNameRequired);
      return;
    }
    final p = _place;
    Navigator.of(context).pop(
      _StopEdit(
        stop: widget.item.stop.copyWith(
          name: name,
          landmark: _landmark.text.trim(),
          location: () =>
              p == null ? null : (lat: p.latitude, lng: p.longitude),
        ),
        toLeg: widget.isFirst ? 0 : _min(_to),
        backLeg: widget.isLast ? 0 : _min(_back),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final p = _place;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
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
            Text(l10n.busEditStop, style: context.text.titleMedium),
            const SizedBox(height: CsSpace.sm),
            TextField(
              controller: _name,
              maxLength: maxStopName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.busStopName,
                errorText: _nameError,
                counterText: '',
              ),
            ),
            TextField(
              controller: _landmark,
              maxLength: maxStopLandmark,
              decoration: InputDecoration(
                labelText: l10n.busLandmark,
                counterText: '',
              ),
            ),
            if (widget.isFirst)
              _Note(icon: CsIcons.time, text: l10n.busFirstStopNote)
            else
              _MinutesField(
                controller: _to,
                label: l10n.busLegFrom(widget.fromName),
              ),
            if (!widget.mirror) ...[
              const SizedBox(height: CsSpace.sm),
              if (widget.isLast)
                _Note(icon: CsIcons.time, text: l10n.busLastStopNote)
              else
                _MinutesField(
                  controller: _back,
                  label: l10n.busLegBackFrom(widget.backFromName),
                ),
            ],
            const SizedBox(height: CsSpace.xs),
            Text(
              l10n.busLegHint,
              style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: CsSpace.md),
            Material(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(CsRadius.md),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(
                  p == null ? CsIcons.place : CsIcons.placeFill,
                  color: p == null ? cs.textSecondary : widget.color,
                ),
                title: Text(
                  p == null ? l10n.busLocationNone : l10n.busLocationSet,
                ),
                subtitle: p == null
                    ? null
                    : Text(
                        '${p.latitude.toStringAsFixed(5)}, '
                        '${p.longitude.toStringAsFixed(5)}',
                      ),
                trailing: TextButton(
                  onPressed: _pick,
                  child: Text(
                    p == null ? l10n.busSetOnMap : l10n.busChangeLocation,
                  ),
                ),
                onTap: _pick,
              ),
            ),
            if (p != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _place = null),
                  child: Text(l10n.busRemoveLocation),
                ),
              ),
            const SizedBox(height: CsSpace.md),
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  onPressed: () =>
                      Navigator.of(context).pop(const _StopEdit.remove()),
                  icon: const Icon(CsIcons.delete),
                  label: Text(l10n.busRemoveStop),
                ),
                const Spacer(),
                FilledButton(onPressed: _done, child: Text(l10n.busSave)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CsSpace.sm),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.cs.primary),
        const SizedBox(width: CsSpace.sm),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}

/// Minutes with quick picks for the usual gaps between stops.
class _MinutesField extends StatelessWidget {
  const _MinutesField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(labelText: label),
        ),
        const SizedBox(height: CsSpace.xs),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, v, _) => Wrap(
            spacing: 6,
            children: [
              for (final m in const [2, 3, 5, 10, 15, 20])
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(l10n.busMinutesValue(m)),
                  selected: v.text == '$m',
                  showCheckmark: false,
                  onSelected: (_) => controller.text = '$m',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
