import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/widgets/notice_banner.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';
import '../widgets/editor_widgets.dart';

/// Add or edit a class (CR). Built for speed: a class can be put on several
/// days at once (one entry per day, so each can later get its own room or
/// time), course details already in the routine are suggested, and "Save
/// and add another" keeps the days and starts the next class when this one
/// ends.
///
/// Editing changes the class that was opened; days picked besides its own
/// get a copy, and unpicking its day moves it to the first picked day.
class SlotEditorPage extends StatefulWidget {
  const SlotEditorPage({super.key, required this.groupId, this.slotId});

  final String groupId;

  /// null = a new class.
  final String? slotId;

  @override
  State<SlotEditorPage> createState() => _SlotEditorPageState();
}

class _SlotEditorPageState extends State<SlotEditorPage> {
  /// Read fresh each time: classes added here appear in the suggestions.
  ClassGroup? get _group =>
      context.read<MyClassesCubit>().state.group(widget.groupId);
  late final ClassSlot? _slot = widget.slotId == null
      ? null
      : _group?.slots.where((s) => s.id == widget.slotId).firstOrNull;

  late final _code = TextEditingController(text: _slot?.courseCode);
  late final _title = TextEditingController(text: _slot?.courseTitle);
  late final _teacher = TextEditingController(text: _slot?.teacher);
  late final _room = TextEditingController(text: _slot?.room);
  final _codeFocus = FocusNode();

  /// Editing: the class's own day to start. New: none until the CR picks,
  /// so a tap never silently adds a day nobody meant.
  late final Set<int> _days = {?_slot?.weekday};
  late int _start = _slot?.startMin ?? 8 * 60 + 30;
  late int _end = _slot?.endMin ?? 10 * 60;
  late ClassKind _kind = _slot?.kind ?? ClassKind.theory;

  bool _busy = false;
  bool _codeMissing = false;
  bool _timeWrong = false;
  bool _dayMissing = false;
  Set<int> _lastDays = const {};
  Failure? _failure;

  bool get _editing => _slot != null;

  /// The student's own class: a name, details and place; no teacher or
  /// theory/lab, and only they see it.
  bool get _personal => widget.groupId == personalGroupId;

  /// Courses already in the routine, latest details first.
  List<ClassSlot> get _courses {
    final seen = <String>{};
    return [
      for (final s in (_group?.slots ?? const <ClassSlot>[]).reversed)
        if (seen.add(s.courseCode.toUpperCase())) s,
    ];
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _teacher.dispose();
    _room.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _useCourse(ClassSlot s) {
    _code.text = s.courseCode;
    if (_title.text.isEmpty) _title.text = s.courseTitle;
    if (_teacher.text.isEmpty) _teacher.text = s.teacher;
    if (_room.text.isEmpty) _room.text = s.room;
    setState(() {
      _kind = s.kind;
      _end = (_start + (s.endMin - s.startMin)).clamp(_start + 5, 24 * 60);
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final now = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now ~/ 60, minute: now % 60),
    );
    if (picked == null) return;
    final m = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        final length = _end - _start;
        _start = m;
        _end = (m + (length > 0 ? length : 90)).clamp(m + 5, 24 * 60);
      } else {
        _end = m;
      }
      _timeWrong = false;
    });
  }

  SlotDraft _draft(int weekday) => SlotDraft(
    courseCode: _code.text.trim(),
    courseTitle: _title.text.trim(),
    teacher: _teacher.text.trim(),
    room: _room.text.trim(),
    weekday: weekday,
    startMin: _start,
    endMin: _end,
    kind: _kind,
  );

  Future<void> _save({bool another = false}) async {
    setState(() {
      _failure = null;
      _codeMissing = _code.text.trim().isEmpty;
      _timeWrong = _end <= _start;
      _dayMissing = _days.isEmpty;
    });
    if (_codeMissing || _timeWrong || _dayMissing) return;
    _lastDays = {..._days};
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyClassesCubit>();
    var added = 0;
    try {
      final days = weekOrder.where(_days.contains).toList();
      if (_editing) {
        // The opened class keeps its day if still picked, else moves.
        final own = days.contains(_slot!.weekday) ? _slot.weekday : days.first;
        await cubit.updateSlot(widget.groupId, _slot.id, _draft(own));
        days.remove(own);
      }
      // One new entry per other day, in week order. A saved day is taken off
      // the selection, so "try again" after an error adds no twins.
      for (final d in days) {
        await cubit.addSlot(widget.groupId, _draft(d));
        added++;
        if (mounted) setState(() => _days.remove(d));
      }
      if (!mounted) return;
      if (!another) {
        context.pop();
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.classesAdded(added))));
      final length = _end - _start;
      for (final c in [_code, _title, _teacher, _room]) {
        c.clear();
      }
      setState(() {
        _days.addAll(_lastDays);
        _start = _end;
        _end = (_start + length).clamp(_start + 5, 24 * 60);
        _kind = ClassKind.theory;
      });
      _codeFocus.requestFocus();
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyClassesCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _personal ? l10n.deletePersonalTitle : l10n.deleteClassTitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.cs.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteClass),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    setState(() => _busy = true);
    try {
      await cubit.deleteSlot(widget.groupId, _slot!.id);
      if (mounted) context.pop();
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_group == null) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _personal
              ? (_editing ? l10n.editPersonalClass : l10n.addPersonalClass)
              : (_editing ? l10n.editClass : l10n.addClass),
        ),
      ),
      body: SafeArea(
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            CsSpace.sm,
            CsSpace.lg,
            CsSpace.lg,
          ),
          children: [
            if (_personal && !_editing) ...[
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: context.cs.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.personalHint,
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.md),
            ],
            RawAutocomplete<ClassSlot>(
              textEditingController: _code,
              focusNode: _codeFocus,
              displayStringForOption: (s) => s.courseCode,
              optionsBuilder: (v) {
                final q = v.text.trim().toUpperCase();
                if (q.isEmpty) return _courses;
                return _courses.where(
                  (s) => s.courseCode.toUpperCase().contains(q),
                );
              },
              onSelected: _useCourse,
              fieldViewBuilder: (context, controller, focus, onSubmit) =>
                  TextField(
                    controller: controller,
                    focusNode: focus,
                    enabled: !_busy,
                    autofocus: !_editing,
                    textCapitalization: _personal
                        ? TextCapitalization.sentences
                        : TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: _personal
                          ? l10n.personalNameLabel
                          : l10n.courseCodeLabel,
                      hintText: _personal
                          ? l10n.personalNameHint
                          : l10n.courseCodeHint,
                      prefixIcon: Icon(
                        _personal ? Icons.edit_note_rounded : Icons.tag_rounded,
                      ),
                      errorText: _codeMissing ? l10n.errorFieldRequired : null,
                    ),
                  ),
              optionsViewBuilder: (context, onSelected, options) =>
                  CourseOptions(options: options, onSelected: onSelected),
            ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _title,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _personal
                    ? l10n.personalDetailsLabel
                    : l10n.courseTitleLabel,
                prefixIcon: const Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: CsSpace.md),
            if (_personal)
              TextField(
                controller: _room,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l10n.placeLabel,
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _teacher,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.teacherLabel,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: CsSpace.md),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _room,
                      enabled: !_busy,
                      decoration: InputDecoration(labelText: l10n.roomLabel),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: CsSpace.lg),
            Text(l10n.daysLabel, style: context.text.labelLarge),
            Text(l10n.daysHint, style: context.text.bodySmall),
            const SizedBox(height: CsSpace.sm),
            Wrap(
              spacing: CsSpace.sm,
              runSpacing: CsSpace.sm,
              children: [
                for (final d in weekOrder)
                  ChoiceChip(
                    label: Text(weekdayShort(context, d)),
                    selected: _days.contains(d),
                    showCheckmark: false,
                    onSelected: _busy
                        ? null
                        : (on) => setState(() {
                            _dayMissing = false;
                            on ? _days.add(d) : _days.remove(d);
                          }),
                  ),
              ],
            ),
            if (_dayMissing) ...[
              const SizedBox(height: CsSpace.xs),
              Text(
                l10n.errorPickDay,
                style: context.text.bodySmall?.copyWith(
                  color: context.cs.error,
                ),
              ),
            ],
            const SizedBox(height: CsSpace.lg),
            Row(
              children: [
                Expanded(
                  child: TimeBox(
                    label: l10n.startsLabel,
                    minutes: _start,
                    onTap: _busy ? null : () => _pickTime(start: true),
                  ),
                ),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: TimeBox(
                    label: l10n.endsLabel,
                    minutes: _end,
                    error: _timeWrong,
                    onTap: _busy ? null : () => _pickTime(start: false),
                  ),
                ),
              ],
            ),
            if (_timeWrong) ...[
              const SizedBox(height: CsSpace.xs),
              Text(
                l10n.errorEndBeforeStart,
                style: context.text.bodySmall?.copyWith(
                  color: context.cs.error,
                ),
              ),
            ],
            if (!_personal) ...[
              const SizedBox(height: CsSpace.lg),
              SegmentedButton<ClassKind>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ClassKind.theory,
                    label: Text(l10n.classTheory),
                    icon: const Icon(Icons.menu_book_outlined),
                  ),
                  ButtonSegment(
                    value: ClassKind.lab,
                    label: Text(l10n.classLab),
                    icon: const Icon(Icons.science_outlined),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: _busy
                    ? null
                    : (v) => setState(() => _kind = v.first),
              ),
            ],
            if (_failure != null) ...[
              const SizedBox(height: CsSpace.md),
              NoticeBanner(text: classErrorText(l10n, _failure!)),
            ],
            const SizedBox(height: CsSpace.lg),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveProfile),
            ),
            const SizedBox(height: CsSpace.sm),
            if (_editing)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: context.cs.error),
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.deleteClass),
              )
            else
              OutlinedButton(
                onPressed: _busy ? null : () => _save(another: true),
                child: Text(l10n.saveAndAddAnother),
              ),
          ],
        ),
      ),
    );
  }
}
