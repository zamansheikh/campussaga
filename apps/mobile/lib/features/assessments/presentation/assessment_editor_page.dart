import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/clock.dart';
import '../../auth/presentation/widgets/notice_banner.dart';
import '../../classes/presentation/bloc/my_classes_cubit.dart';
import '../../classes/presentation/class_format.dart';
import '../../classes/presentation/widgets/class_sheet.dart';
import '../../classes/presentation/widgets/editor_widgets.dart';
import 'assessment_widgets.dart';

/// Adds or changes a test or deadline (any member adds; who added it or a
/// CR changes it).
class AssessmentEditorPage extends StatefulWidget {
  const AssessmentEditorPage({
    super.key,
    required this.groupId,
    this.assessmentId,
    this.courseCode,
    this.date,
  });

  final String groupId;

  /// The one to change; null = a new one.
  final String? assessmentId;

  /// Prefilled for a new one (e.g. from a class).
  final String? courseCode;
  final DateTime? date;

  @override
  State<AssessmentEditorPage> createState() => _AssessmentEditorPageState();
}

class _AssessmentEditorPageState extends State<AssessmentEditorPage> {
  ClassGroup? get _group =>
      context.read<MyClassesCubit>().state.group(widget.groupId);

  late final Assessment? _old = widget.assessmentId == null
      ? null
      : _group?.assessments
            .where((a) => a.id == widget.assessmentId)
            .firstOrNull;

  bool get _editing => widget.assessmentId != null;

  late AssessmentKind _kind = _old?.kind ?? AssessmentKind.classTest;
  late DateTime _date = _old?.date ?? widget.date ?? _defaultDate();
  late int? _start =
      _old?.startMin ??
      (_courseSlot?.weekday == _date.weekday ? _courseSlot?.startMin : null);
  late int? _end = _old?.endMin;
  late final _code = TextEditingController(
    text: _old?.courseCode ?? widget.courseCode,
  );
  late final _title = TextEditingController(
    text: _old?.courseTitle ?? _courseSlot?.courseTitle,
  );
  late final _room = TextEditingController(
    text: _old?.room ?? _courseSlot?.room,
  );
  late final _topics = TextEditingController(text: _old?.topics);
  final _codeFocus = FocusNode();

  bool _busy = false;
  bool _codeMissing = false;
  bool _timeWrong = false;
  Failure? _failure;

  /// The weekly class of the prefilled course (for its time and room).
  late final ClassSlot? _courseSlot = () {
    final code = widget.courseCode;
    if (code == null) return null;
    final slots = (_group?.slots ?? const <ClassSlot>[]).where(
      (s) => courseKey(s.courseCode) == courseKey(code),
    );
    return slots.where((s) => s.weekday == widget.date?.weekday).firstOrNull ??
        slots.firstOrNull;
  }();

  DateTime _defaultDate() {
    final now = appNow();
    return DateTime(now.year, now.month, now.day + 1);
  }

  List<ClassSlot> get _courses {
    final seen = <String>{};
    return [
      for (final s in (_group?.slots ?? const <ClassSlot>[]))
        if (seen.add(courseKey(s.courseCode))) s,
    ];
  }

  @override
  void dispose() {
    for (final c in [_code, _title, _room, _topics]) {
      c.dispose();
    }
    _codeFocus.dispose();
    super.dispose();
  }

  void _useCourse(ClassSlot s) {
    _code.text = s.courseCode;
    if (_title.text.isEmpty) _title.text = s.courseTitle;
    if (_room.text.isEmpty) _room.text = s.room;
    // The class's time on that weekday, if it meets then.
    final same = _group?.slots.where(
      (x) =>
          courseKey(x.courseCode) == courseKey(s.courseCode) &&
          x.weekday == _date.weekday,
    );
    if (_start == null && same != null && same.isNotEmpty) {
      setState(() => _start = same.first.startMin);
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(appNow());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final now = (start ? _start : _end) ?? (_start ?? 10 * 60) + 30;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now ~/ 60 % 24, minute: now % 60),
    );
    if (picked == null) return;
    final m = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        final length = _start != null && _end != null ? _end! - _start! : null;
        _start = m;
        if (length != null) _end = (m + length).clamp(m + 5, 24 * 60);
      } else {
        _end = m;
      }
      _timeWrong = false;
    });
  }

  Future<void> _save() async {
    final start = _start;
    final end = _end;
    setState(() {
      _failure = null;
      _codeMissing = _code.text.trim().isEmpty;
      _timeWrong = start != null && end != null && end <= start;
    });
    if (_codeMissing || _timeWrong) return;
    final draft = AssessmentDraft(
      kind: _kind,
      courseCode: _code.text.trim(),
      courseTitle: _title.text.trim(),
      date: _date,
      startMin: start,
      endMin: start == null || _kind.isDeadline ? null : end,
      room: _room.text.trim(),
      topics: _topics.text.trim(),
    );
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<MyClassesCubit>();
    try {
      if (_editing) {
        await cubit.updateAssessment(widget.groupId, _old!.id, draft);
      } else {
        await cubit.addAssessment(widget.groupId, draft);
      }
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.testSaved)));
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
    if (_group == null || (_editing && _old == null)) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final deadline = _kind.isDeadline;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? l10n.editTest : l10n.addTest)),
      body: SafeArea(
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            CsSpace.sm,
            CsSpace.lg,
            CsSpace.lg,
          ),
          children: [
            Text(l10n.testKindLabel, style: context.text.titleSmall),
            const SizedBox(height: CsSpace.sm),
            Wrap(
              spacing: CsSpace.sm,
              runSpacing: CsSpace.sm,
              children: [
                for (final k in AssessmentKind.values)
                  ChoiceChip(
                    avatar: Icon(assessmentIcon(k), size: 18),
                    label: Text(assessmentKindText(l10n, k)),
                    selected: _kind == k,
                    showCheckmark: false,
                    onSelected: _busy ? null : (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
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
                      prefixIcon: const Icon(Icons.tag_rounded),
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
              decoration: InputDecoration(
                labelText: l10n.courseTitleLabel,
                prefixIcon: const Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: CsSpace.md),
            _DateBox(
              label: l10n.dateLabel,
              text: dateText(context, _date),
              onTap: _busy ? null : _pickDate,
            ),
            const SizedBox(height: CsSpace.md),
            if (_start == null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _busy ? null : () => _pickTime(start: true),
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(l10n.testAddTime),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TimeBox(
                      label: deadline ? l10n.dueLabel : l10n.startsLabel,
                      minutes: _start!,
                      onTap: _busy ? null : () => _pickTime(start: true),
                    ),
                  ),
                  if (!deadline) ...[
                    const SizedBox(width: CsSpace.md),
                    Expanded(
                      child: _end == null
                          ? OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _pickTime(start: false),
                              child: Text(l10n.testAddEnd),
                            )
                          : TimeBox(
                              label: l10n.endsLabel,
                              minutes: _end!,
                              error: _timeWrong,
                              onTap: _busy
                                  ? null
                                  : () => _pickTime(start: false),
                            ),
                    ),
                  ],
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _start = null;
                          _end = null;
                          _timeWrong = false;
                        }),
                  child: Text(l10n.testNoTime),
                ),
              ),
            ],
            if (_timeWrong)
              Text(
                l10n.errorEndBeforeStart,
                style: context.text.bodySmall?.copyWith(
                  color: context.cs.error,
                ),
              ),
            const SizedBox(height: CsSpace.sm),
            TextField(
              controller: _room,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l10n.roomLabel,
                prefixIcon: const Icon(Icons.meeting_room_outlined),
              ),
            ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _topics,
              enabled: !_busy,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.topicsLabel,
                hintText: l10n.topicsHint,
                prefixIcon: const Icon(Icons.notes_rounded),
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

/// A tappable date (opens the date picker).
class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.text, this.onTap});

  final String label;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.md),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.event_outlined, color: cs.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.labelMedium),
                    Text(text, style: context.text.titleMedium),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: cs.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
