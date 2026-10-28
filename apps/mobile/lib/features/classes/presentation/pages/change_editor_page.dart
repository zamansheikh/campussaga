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
import '../widgets/class_sheet.dart';
import '../widgets/editor_widgets.dart';

/// For one date only (CR): move a class to another day, time or room, or
/// add an extra class. The weekly routine stays the same.
class ChangeEditorPage extends StatefulWidget {
  const ChangeEditorPage({
    super.key,
    required this.groupId,
    required this.date,
    this.slotId,
  });

  final String groupId;

  /// The class's own date (for a move), or the extra class's date.
  final DateTime date;

  /// The class to move; null = a new extra class.
  final String? slotId;

  @override
  State<ChangeEditorPage> createState() => _ChangeEditorPageState();
}

class _ChangeEditorPageState extends State<ChangeEditorPage> {
  ClassGroup? get _group =>
      context.read<MyClassesCubit>().state.group(widget.groupId);

  /// The class as it is on that date (with any earlier change).
  late final ClassOnDay? _item = widget.slotId == null || _group == null
      ? null
      : classesOn([
          _group!,
        ], widget.date).where((c) => c.slot.id == widget.slotId).firstOrNull;

  bool get _extra => widget.slotId == null;

  /// An earlier move of this class on this date (edited, not stacked).
  ClassChange? get _move =>
      _item?.change?.kind == ChangeKind.moved ? _item!.change : null;

  late DateTime _date = _move?.newDate ?? widget.date;
  late int _start = _move?.startMin ?? _item?.startMin ?? 14 * 60;
  late int _end = _move?.endMin ?? _item?.endMin ?? 15 * 60 + 30;
  late ClassKind _kind = ClassKind.theory;
  late final _code = TextEditingController();
  late final _title = TextEditingController();
  late final _teacher = TextEditingController();
  late final _room = TextEditingController(
    text: (_move?.room.isNotEmpty ?? false) ? _move!.room : _item?.slot.room,
  );
  late final _note = TextEditingController(text: _move?.note);
  final _codeFocus = FocusNode();

  bool _busy = false;
  bool _codeMissing = false;
  bool _timeWrong = false;
  Failure? _failure;

  List<ClassSlot> get _courses {
    final seen = <String>{};
    return [
      for (final s in (_group?.slots ?? const <ClassSlot>[]).reversed)
        if (seen.add(s.courseCode.toUpperCase())) s,
    ];
  }

  @override
  void dispose() {
    for (final c in [_code, _title, _teacher, _room, _note]) {
      c.dispose();
    }
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

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(appNow());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() {
      _failure = null;
      _codeMissing = _extra && _code.text.trim().isEmpty;
      _timeWrong = _end <= _start;
    });
    if (_codeMissing || _timeWrong) return;
    final room = _room.text.trim();
    final draft = _extra
        ? ChangeDraft.extra(
            date: _date,
            courseCode: _code.text.trim(),
            courseTitle: _title.text.trim(),
            teacher: _teacher.text.trim(),
            room: room,
            classKind: _kind,
            startMin: _start,
            endMin: _end,
            note: _note.text.trim(),
          )
        : ChangeDraft.move(
            slotId: widget.slotId!,
            date: widget.date,
            newDate: _date == widget.date ? null : _date,
            startMin: _start,
            endMin: _end,
            // The weekly room means "unchanged".
            room: room == _item!.slot.room ? '' : room,
            note: _note.text.trim(),
          );
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<MyClassesCubit>().addChange(widget.groupId, draft);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.changeSaved)));
      context.pop();
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = _group;
    if (g == null || (!_extra && _item == null)) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final item = _item;
    return Scaffold(
      appBar: AppBar(
        title: Text(_extra ? l10n.addExtraClass : l10n.changeTimeOrRoom),
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
            if (item != null) ...[
              Text(item.slot.courseCode, style: context.text.titleLarge),
              if (item.slot.courseTitle.isNotEmpty)
                Text(item.slot.courseTitle, style: context.text.bodyMedium),
              const SizedBox(height: CsSpace.sm),
            ],
            NoticeCard(
              icon: _date == widget.date ? CsIcons.date : CsIcons.newSemester,
              text: _extra || _date == widget.date
                  ? l10n.onlyThisDay(dateText(context, _date))
                  : l10n.movedDayNotice(
                      dateText(context, widget.date),
                      dateText(context, _date),
                    ),
              onTap: _busy ? null : _pickDate,
            ),
            if (!_extra && _date == widget.date)
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xs),
                child: Text(l10n.dayTapToChange, style: context.text.bodySmall),
              ),
            const SizedBox(height: CsSpace.lg),
            if (_extra) ...[
              RawAutocomplete<ClassSlot>(
                textEditingController: _code,
                focusNode: _codeFocus,
                displayStringForOption: (s) => s.courseCode,
                optionsBuilder: (v) {
                  final q = v.text.trim().toUpperCase();
                  return q.isEmpty
                      ? _courses
                      : _courses.where(
                          (s) => s.courseCode.toUpperCase().contains(q),
                        );
                },
                onSelected: _useCourse,
                fieldViewBuilder: (context, controller, focus, onSubmit) =>
                    TextField(
                      controller: controller,
                      focusNode: focus,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.courseCodeLabel,
                        hintText: l10n.courseCodeHint,
                        prefixIcon: const Icon(CsIcons.code),
                        errorText: _codeMissing
                            ? l10n.errorFieldRequired
                            : null,
                      ),
                    ),
                optionsViewBuilder: (context, onSelected, options) =>
                    CourseOptions(options: options, onSelected: onSelected),
              ),
              const SizedBox(height: CsSpace.md),
              TextField(
                controller: _title,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l10n.courseTitleLabel,
                  prefixIcon: const Icon(CsIcons.course),
                ),
              ),
              const SizedBox(height: CsSpace.md),
              TextField(
                controller: _teacher,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l10n.teacherLabel,
                  prefixIcon: const Icon(CsIcons.profile),
                ),
              ),
              const SizedBox(height: CsSpace.md),
            ],
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
            if (_timeWrong)
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xs),
                child: Text(
                  l10n.errorEndBeforeStart,
                  style: context.text.bodySmall?.copyWith(
                    color: context.cs.error,
                  ),
                ),
              ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _room,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l10n.roomLabel,
                prefixIcon: const Icon(CsIcons.room),
              ),
            ),
            if (_extra) ...[
              const SizedBox(height: CsSpace.md),
              SegmentedButton<ClassKind>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ClassKind.theory,
                    label: Text(l10n.classTheory),
                  ),
                  ButtonSegment(
                    value: ClassKind.lab,
                    label: Text(l10n.classLab),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: _busy
                    ? null
                    : (v) => setState(() => _kind = v.first),
              ),
            ],
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                hintText: l10n.noteHint,
                prefixIcon: const Icon(CsIcons.note),
              ),
            ),
            if (_failure != null) ...[
              const SizedBox(height: CsSpace.sm),
              NoticeBanner(text: classErrorText(l10n, _failure!)),
            ],
            const SizedBox(height: CsSpace.md),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveProfile),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft info row, tappable when [onTap] is set (e.g. pick the date).
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(CsRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: cs.onPrimaryContainer, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: context.text.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(CsIcons.edit, size: 18, color: cs.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
