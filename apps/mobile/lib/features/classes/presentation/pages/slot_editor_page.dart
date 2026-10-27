import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

/// Add or edit one class (CR). Built for speed: course details already in
/// the routine are suggested, and "Save and add another" keeps the day and
/// starts the next class when this one ends.
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

  late int _weekday = _slot?.weekday ?? _defaultDay();
  late int _start = _slot?.startMin ?? 8 * 60 + 30;
  late int _end = _slot?.endMin ?? 10 * 60;
  late ClassKind _kind = _slot?.kind ?? ClassKind.theory;

  bool _busy = false;
  bool _codeMissing = false;
  bool _timeWrong = false;
  Failure? _failure;

  bool get _editing => _slot != null;

  /// Today, or Saturday on Friday (the weekend).
  static int _defaultDay() {
    final d = appNow().weekday;
    return d == DateTime.friday ? DateTime.saturday : d;
  }

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

  Future<void> _save({bool another = false}) async {
    final draft = SlotDraft(
      courseCode: _code.text.trim(),
      courseTitle: _title.text.trim(),
      teacher: _teacher.text.trim(),
      room: _room.text.trim(),
      weekday: _weekday,
      startMin: _start,
      endMin: _end,
      kind: _kind,
    );
    setState(() {
      _failure = null;
      _codeMissing = draft.courseCode.isEmpty;
      _timeWrong = draft.endMin <= draft.startMin;
    });
    if (_codeMissing || _timeWrong) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyClassesCubit>();
    try {
      if (_editing) {
        await cubit.updateSlot(widget.groupId, _slot!.id, draft);
      } else {
        await cubit.addSlot(widget.groupId, draft);
      }
      if (!mounted) return;
      if (!another) {
        context.pop();
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.classAdded)));
      final length = _end - _start;
      for (final c in [_code, _title, _teacher, _room]) {
        c.clear();
      }
      setState(() {
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
        title: Text(l10n.deleteClassTitle),
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
      appBar: AppBar(title: Text(_editing ? l10n.editClass : l10n.addClass)),
      body: SafeArea(
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            CsSpace.sm,
            CsSpace.lg,
            CsSpace.lg,
          ),
          children: [
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
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.courseCodeLabel,
                      hintText: l10n.courseCodeHint,
                      prefixIcon: const Icon(Icons.tag_rounded),
                      errorText: _codeMissing ? l10n.errorFieldRequired : null,
                    ),
                  ),
              optionsViewBuilder: (context, onSelected, options) =>
                  _CourseOptions(options: options, onSelected: onSelected),
            ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _title,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.courseTitleLabel,
                prefixIcon: const Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: CsSpace.md),
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
            Text(l10n.dayLabel, style: context.text.labelLarge),
            const SizedBox(height: CsSpace.sm),
            Wrap(
              spacing: CsSpace.sm,
              runSpacing: CsSpace.sm,
              children: [
                for (final d in weekOrder)
                  ChoiceChip(
                    label: Text(weekdayShort(context, d)),
                    selected: d == _weekday,
                    showCheckmark: false,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _weekday = d),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
            Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    label: l10n.startsLabel,
                    minutes: _start,
                    onTap: _busy ? null : () => _pickTime(start: true),
                  ),
                ),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: _TimeBox(
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

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.minutes,
    required this.onTap,
    this.error = false,
  });

  final String label;
  final int minutes;
  final VoidCallback? onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.md),
        side: BorderSide(color: error ? cs.error : cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: cs.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.labelMedium),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        clockText(context, minutes),
                        style: context.text.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseOptions extends StatelessWidget {
  const _CourseOptions({required this.options, required this.onSelected});

  final Iterable<ClassSlot> options;
  final AutocompleteOnSelected<ClassSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: CsSpace.xs),
        child: Material(
          elevation: 6,
          shadowColor: Colors.black26,
          color: context.cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CsRadius.md),
            side: BorderSide(color: context.cs.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: CsSpace.xs),
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    title: Text(o.courseCode),
                    subtitle: o.courseTitle.isEmpty
                        ? null
                        : Text(o.courseTitle),
                    onTap: () => onSelected(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
