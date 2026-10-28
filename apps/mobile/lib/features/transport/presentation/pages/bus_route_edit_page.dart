import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../bus_cubit.dart';
import '../bus_format.dart';

/// Create a route ([routeId] null) or edit its name, colour, notes and
/// whether students see it.
class BusRouteEditPage extends StatefulWidget {
  const BusRouteEditPage({super.key, this.routeId});

  final String? routeId;

  @override
  State<BusRouteEditPage> createState() => _BusRouteEditPageState();
}

class _BusRouteEditPageState extends State<BusRouteEditPage> {
  final _cubit = getIt<BusCubit>();
  late final BusRoute? _route = widget.routeId == null
      ? null
      : _cubit.state.route(widget.routeId!);
  late final _name = TextEditingController(text: _route?.name ?? '');
  late final _notes = TextEditingController(text: _route?.notes ?? '');
  late String _color = _route?.color ?? busColors.first;
  late bool _active = _route?.active ?? true;
  bool _saving = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.busNameRequired);
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await _cubit.saveRoute(
        id: widget.routeId,
        name: name,
        color: _color,
        notes: _notes.text.trim(),
        active: _active,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.busSaved)));
      if (widget.routeId == null) {
        context.pushReplacement(Routes.busRoute(r.id));
      } else {
        context.pop();
      }
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(busErrorText(l10n, f))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.routeId == null ? l10n.busAddRoute : l10n.busEditRoute,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(CsSpace.screen),
        children: [
          TextField(
            controller: _name,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.busRouteName,
              hintText: l10n.busRouteNameHint,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: CsSpace.sm),
          Text(l10n.busColor, style: context.text.labelLarge),
          const SizedBox(height: CsSpace.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in busColors)
                Semantics(
                  button: true,
                  selected: c == _color,
                  label: c,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(
                          0xFF000000 | int.parse(c.substring(1), radix: 16),
                        ),
                        border: Border.all(
                          color: c == _color ? cs.textPrimary : cs.border,
                          width: c == _color ? 3 : 1,
                        ),
                      ),
                      child: c == _color
                          ? const Icon(
                              CsIcons.checkCircle,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: CsSpace.lg),
          TextField(
            controller: _notes,
            maxLength: 500,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n.busNotes,
              hintText: l10n.busNotesHint,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: Text(l10n.busShowRoute),
            subtitle: Text(l10n.busShowRouteHint),
          ),
          const SizedBox(height: CsSpace.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.busSave),
          ),
        ],
      ),
    );
  }
}
