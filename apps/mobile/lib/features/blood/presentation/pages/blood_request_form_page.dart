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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../blood_format.dart';
import '../widgets/blood_widgets.dart';

enum _Day { today, tomorrow, other }

/// Ask the university's donors for blood: group, bags, hospital, when,
/// contact. Only verified students can post (requests stay real).
class BloodRequestFormPage extends StatefulWidget {
  const BloodRequestFormPage({super.key});

  @override
  State<BloodRequestFormPage> createState() => _BloodRequestFormPageState();
}

class _BloodRequestFormPageState extends State<BloodRequestFormPage> {
  BloodGroup? _group;
  int _units = 1;
  final _hospital = TextEditingController();
  final _area = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  _Day _day = _Day.today;
  DateTime _date = DateUtils.dateOnly(appNow());
  late TimeOfDay _time = _defaultTime();
  bool _urgent = false;
  bool _tried = false;
  bool _posting = false;

  /// Two hours from now, on the hour.
  static TimeOfDay _defaultTime() {
    final t = appNow().add(const Duration(hours: 2));
    return TimeOfDay(
      hour: t.minute > 0 ? (t.hour + 1) % 24 : t.hour,
      minute: 0,
    );
  }

  @override
  void initState() {
    super.initState();
    _name.text = context.read<AuthBloc>().state.user?.displayName ?? '';
    // The donor profile's phone, if any, to save typing.
    getIt<BloodRepository>().me().then((d) {
      if (mounted && d != null && _phone.text.isEmpty) {
        setState(() => _phone.text = d.phone);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    for (final c in [_hospital, _area, _name, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _neededBy =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  bool get _timeOk {
    final now = appNow();
    final at = _neededBy;
    return !at.isBefore(now.subtract(const Duration(hours: 1))) &&
        !at.isAfter(now.add(const Duration(days: 30)));
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(appNow());
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (d != null) {
      setState(() {
        _date = d;
        _day = d == today
            ? _Day.today
            : d == today.add(const Duration(days: 1))
            ? _Day.tomorrow
            : _Day.other;
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _setDay(_Day day) {
    if (day == _Day.other) {
      _pickDate();
      return;
    }
    final today = DateUtils.dateOnly(appNow());
    setState(() {
      _day = day;
      _date = day == _Day.today ? today : today.add(const Duration(days: 1));
    });
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _tried = true);
    final phone = cleanPhone(_phone.text);
    if (_group == null ||
        _hospital.text.trim().length < 2 ||
        _name.text.trim().isEmpty ||
        phone == null ||
        phone.isEmpty ||
        !_timeOk) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _posting = true);
    try {
      final r = await getIt<BloodRepository>().create(
        BloodRequestDraft(
          bloodGroup: _group!,
          units: _units,
          hospital: _hospital.text,
          area: _area.text,
          neededBy: _neededBy,
          urgent: _urgent,
          contactName: _name.text,
          contactPhone: phone,
          note: _note.text,
        ),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r.notified > 0
                ? l10n.bloodNotified(r.notified, r.bloodGroup.label)
                : l10n.bloodPostedNone(r.bloodGroup.label),
          ),
        ),
      );
      unawaited(router.pushReplacement(Routes.bloodRequest(r.id)));
    } on Failure catch (f) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(bloodErrorText(context, f))),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final verified = context.select(
      (AuthBloc b) => b.state.user?.verified ?? false,
    );
    if (!verified) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bloodRequestAction)),
        body: CsEmptyState(
          icon: CsIcons.verifiedOutline,
          title: l10n.bloodVerifyFirst,
          actionLabel: l10n.verifyWithUniEmail,
          onAction: () => context.push(Routes.verifyEmail),
        ),
      );
    }
    final phone = cleanPhone(_phone.text);
    String? err(bool bad, String text) => _tried && bad ? text : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bloodRequestAction)),
      body: CsPage(
        children: [
          Text(l10n.bloodGroupNeeded, style: context.text.titleSmall),
          const SizedBox(height: CsSpace.sm),
          BloodGroupPicker(
            selected: _group,
            onSelected: (g) => setState(() => _group = g),
          ),
          if (_tried && _group == null)
            Padding(
              padding: const EdgeInsets.only(top: CsSpace.xs),
              child: Text(
                l10n.bloodGroupNeeded,
                style: context.text.bodySmall?.copyWith(color: cs.error),
              ),
            ),
          if (_group != null)
            Padding(
              padding: const EdgeInsets.only(top: CsSpace.sm),
              child: Text(
                l10n.bloodCompatible(compatibleText(_group!)),
                style: context.text.bodySmall,
              ),
            ),
          const SizedBox(height: CsSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.bloodUnitsLabel,
                  style: context.text.titleSmall,
                ),
              ),
              IconButton.outlined(
                tooltip: '−',
                onPressed: _units > 1 ? () => setState(() => _units--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  l10n.bloodUnits(_units),
                  textAlign: TextAlign.center,
                  style: context.text.titleSmall,
                ),
              ),
              IconButton.outlined(
                tooltip: '+',
                onPressed: _units < BloodRequestDraft.maxUnits
                    ? () => setState(() => _units++)
                    : null,
                icon: const Icon(CsIcons.add),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.md),
          TextField(
            controller: _hospital,
            maxLength: BloodRequestDraft.maxHospital,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.bloodHospital,
              hintText: l10n.bloodHospitalHint,
              prefixIcon: const Icon(CsIcons.place),
              counterText: '',
              errorText: err(
                _hospital.text.trim().length < 2,
                l10n.bloodHospitalHint,
              ),
            ),
          ),
          const SizedBox(height: CsSpace.sm),
          TextField(
            controller: _area,
            maxLength: BloodRequestDraft.maxArea,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.bloodArea,
              hintText: l10n.bloodAreaHint,
              prefixIcon: const Icon(CsIcons.map),
              counterText: '',
            ),
          ),
          const SizedBox(height: CsSpace.md),
          Text(l10n.bloodWhen, style: context.text.titleSmall),
          const SizedBox(height: CsSpace.sm),
          Wrap(
            spacing: CsSpace.sm,
            runSpacing: CsSpace.sm,
            children: [
              ChoiceChip(
                label: Text(l10n.bloodWhenToday),
                selected: _day == _Day.today,
                showCheckmark: false,
                onSelected: (_) => _setDay(_Day.today),
              ),
              ChoiceChip(
                label: Text(l10n.bloodWhenTomorrow),
                selected: _day == _Day.tomorrow,
                showCheckmark: false,
                onSelected: (_) => _setDay(_Day.tomorrow),
              ),
              ChoiceChip(
                avatar: const Icon(CsIcons.date, size: 18),
                label: Text(
                  _day == _Day.other
                      ? bloodDateText(context, _date)
                      : l10n.bloodWhenPick,
                ),
                selected: _day == _Day.other,
                showCheckmark: false,
                onSelected: (_) => _setDay(_Day.other),
              ),
              // The same kind of chip as the days (always chosen).
              ChoiceChip(
                avatar: const Icon(CsIcons.time, size: 18),
                label: Text(_time.format(context)),
                selected: false,
                showCheckmark: false,
                onSelected: (_) => _pickTime(),
              ),
            ],
          ),
          if (_tried && !_timeOk)
            Padding(
              padding: const EdgeInsets.only(top: CsSpace.xs),
              child: Text(
                l10n.bloodWhen,
                style: context.text.bodySmall?.copyWith(color: cs.error),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.bloodUrgent),
            subtitle: Text(l10n.bloodUrgentHint),
            value: _urgent,
            activeThumbColor: CsBloodBadge.color,
            onChanged: (v) => setState(() => _urgent = v),
          ),
          const SizedBox(height: CsSpace.sm),
          Text(l10n.bloodContact, style: context.text.titleSmall),
          const SizedBox(height: CsSpace.sm),
          TextField(
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.bloodContactName,
              prefixIcon: const Icon(CsIcons.profile),
              counterText: '',
              errorText: err(_name.text.trim().isEmpty, l10n.bloodContactName),
            ),
          ),
          const SizedBox(height: CsSpace.sm),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.bloodContactPhone,
              hintText: '01712345678',
              prefixIcon: const Icon(CsIcons.call),
              errorText: err(
                phone == null || phone.isEmpty,
                l10n.bloodPhoneInvalid,
              ),
            ),
          ),
          const SizedBox(height: CsSpace.sm),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            maxLength: BloodRequestDraft.maxNote,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.bloodNote,
              hintText: l10n.bloodNoteHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: CsSpace.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: CsBloodBadge.color,
              foregroundColor: Colors.white,
            ),
            onPressed: _posting ? null : _post,
            icon: _posting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CsIcons.send),
            label: Text(l10n.bloodPost),
          ),
        ],
      ),
    );
  }
}
