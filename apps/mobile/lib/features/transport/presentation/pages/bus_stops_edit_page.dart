import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';

/// A route's stops, from the far end to campus, with the minutes from the
/// first stop (to campus) or from campus (the way back).
class BusStopsEditPage extends StatefulWidget {
  const BusStopsEditPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<BusStopsEditPage> createState() => _BusStopsEditPageState();
}

class _Item {
  _Item(this.key, this.stop);

  final int key; // stable list key: new stops have no id yet
  BusStop stop;
}

class _BusStopsEditPageState extends State<BusStopsEditPage> {
  final _cubit = getIt<BusCubit>();
  late final _items = [
    for (final (i, s)
        in (_cubit.state.route(widget.routeId)?.stops ?? const <BusStop>[])
            .indexed)
      _Item(i, s),
  ];
  late int _nextKey = _items.length;
  bool _saving = false;

  Future<void> _editStop([_Item? item]) async {
    final stop = await showDialog<BusStop>(
      context: context,
      builder: (_) => _StopDialog(stop: item?.stop),
    );
    if (stop == null) return;
    setState(() {
      if (item == null) {
        _items.add(_Item(_nextKey++, stop));
      } else {
        item.stop = stop;
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _cubit.setStops(widget.routeId, [for (final i in _items) i.stop]);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.busSaved)));
      context.pop();
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(busErrorText(l10n, f))));
    }
  }

  String _minutes(AppLocalizations l10n, BusStop s) => [
    if (s.toCampusMin != null)
      '${l10n.busToCampus}: ${l10n.busMinutesValue(s.toCampusMin!)}',
    if (s.fromCampusMin != null)
      '${l10n.busFromCampus}: ${l10n.busMinutesValue(s.fromCampusMin!)}',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.busEditStops),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.busSave),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _editStop,
        icon: const Icon(CsIcons.add),
        label: Text(l10n.busAddStop),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.screen,
              CsSpace.sm,
              CsSpace.screen,
              CsSpace.sm,
            ),
            child: Text(
              l10n.busStopsHint,
              style: context.text.bodySmall?.copyWith(
                color: context.cs.textSecondary,
              ),
            ),
          ),
          if (_saving) const LinearProgressIndicator(),
          Expanded(
            child: _items.isEmpty
                ? CsEmptyState(icon: CsIcons.place, title: l10n.busNoStops)
                : ReorderableListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    onReorderItem: (from, to) => setState(
                      () => _items.insert(to, _items.removeAt(from)),
                    ),
                    children: [
                      for (final (i, item) in _items.indexed)
                        ListTile(
                          key: ValueKey(item.key),
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text('${i + 1}'),
                          ),
                          title: Text(item.stop.name),
                          subtitle: Text(
                            [
                              if (item.stop.landmark.isNotEmpty)
                                item.stop.landmark,
                              _minutes(l10n, item.stop),
                            ].where((x) => x.isNotEmpty).join('\n'),
                          ),
                          isThreeLine: item.stop.landmark.isNotEmpty,
                          onTap: () => _editStop(item),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.deleteAction,
                                icon: const Icon(CsIcons.delete),
                                onPressed: () =>
                                    setState(() => _items.remove(item)),
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(CsIcons.swap),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StopDialog extends StatefulWidget {
  const _StopDialog({this.stop});

  final BusStop? stop;

  @override
  State<_StopDialog> createState() => _StopDialogState();
}

class _StopDialogState extends State<_StopDialog> {
  late final _name = TextEditingController(text: widget.stop?.name ?? '');
  late final _landmark = TextEditingController(
    text: widget.stop?.landmark ?? '',
  );
  late final _to = TextEditingController(
    text: widget.stop?.toCampusMin?.toString() ?? '',
  );
  late final _from = TextEditingController(
    text: widget.stop?.fromCampusMin?.toString() ?? '',
  );
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _landmark.dispose();
    _to.dispose();
    _from.dispose();
    super.dispose();
  }

  int? _min(TextEditingController c) {
    return int.tryParse(c.text.trim())?.clamp(0, 600);
  }

  void _done() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = AppLocalizations.of(context).busNameRequired);
      return;
    }
    Navigator.of(context).pop(
      BusStop(
        id: widget.stop?.id ?? '',
        name: name,
        landmark: _landmark.text.trim(),
        toCampusMin: _min(_to),
        fromCampusMin: _min(_from),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    InputDecoration minutes(String label) => InputDecoration(labelText: label);
    return AlertDialog(
      title: Text(widget.stop == null ? l10n.busAddStop : l10n.editAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.stop == null,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.busStopName,
                errorText: _nameError,
              ),
            ),
            TextField(
              controller: _landmark,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.busLandmark),
            ),
            TextField(
              controller: _to,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: minutes(l10n.busToCampusMinutes),
            ),
            const SizedBox(height: CsSpace.sm),
            TextField(
              controller: _from,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: minutes(l10n.busFromCampusMinutes),
            ),
            const SizedBox(height: CsSpace.sm),
            Text(
              l10n.busMinutesHint,
              style: context.text.bodySmall?.copyWith(
                color: context.cs.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _done, child: Text(l10n.busSave)),
      ],
    );
  }
}
