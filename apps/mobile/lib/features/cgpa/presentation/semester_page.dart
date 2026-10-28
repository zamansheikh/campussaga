import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../classes/presentation/bloc/my_classes_cubit.dart';
import 'cgpa_cubit.dart';
import 'cgpa_format.dart';

/// One semester: its GPA and its courses.
class SemesterPage extends StatelessWidget {
  const SemesterPage({super.key, required this.semesterId});

  final String semesterId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CgpaCubit>();
    final book = context.watch<CgpaCubit>().state.book;
    final s = book.semesters.where((x) => x.id == semesterId).firstOrNull;
    if (s == null) return const Scaffold(body: SizedBox.shrink());
    final result = book.semesterGpa(s);
    final replaced = book.replacedCourseIds;
    final fromRoutine = _routineCourses(context, s);

    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCourseSheet(context, cubit, s.id, book.scale),
        icon: const Icon(CsIcons.add),
        label: Text(l10n.cgpaAddCourse),
      ),
      body: CsPage(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.screen,
          CsSpace.sm,
          CsSpace.screen,
          96,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(CsSpace.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.gpa == null
                              ? '–'
                              : gpaText(context, result.gpa!),
                          style: context.text.headlineMedium,
                        ),
                        Text(
                          result.gpa == null
                              ? l10n.cgpaNoGrades
                              : l10n.cgpaGpa('').trim(),
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        creditsText(context, result.creditsAttempted),
                        style: context.text.titleLarge,
                      ),
                      Text(
                        l10n.cgpaCreditsLabel,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (fromRoutine.isNotEmpty && s.courses.isEmpty) ...[
            const SizedBox(height: CsSpace.md),
            CsSection(
              children: [
                CsRow(
                  icon: CsIcons.listAdd,
                  title: l10n.cgpaFromRoutine,
                  subtitle:
                      '${l10n.cgpaFromRoutineHint} '
                      '(${l10n.cgpaCoursesCount(fromRoutine.length)})',
                  onTap: () => cubit.addCourses(s.id, [
                    for (final (code, title, credits) in fromRoutine)
                      CgpaCourse(
                        id: cubit.newId(),
                        code: code,
                        title: title,
                        credits: credits,
                      ),
                  ]),
                ),
              ],
            ),
          ],
          const SizedBox(height: CsSpace.lg),
          if (s.courses.isNotEmpty)
            CsSection(
              children: [
                for (final c in s.courses)
                  _CourseRow(
                    course: c,
                    grade: c.grade(book.scale),
                    replaced: replaced.contains(c.id),
                    onTap: () => showCourseSheet(
                      context,
                      cubit,
                      s.id,
                      book.scale,
                      course: c,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Courses in the student's routine not yet in [s]: (code, title,
  /// credits: 1.5 for a lab-only course, else 3).
  static List<(String, String, double)> _routineCourses(
    BuildContext context,
    Semester s,
  ) {
    final routine = context.select((MyClassesCubit c) => c.state.routine);
    final have = {for (final c in s.courses) c.key};
    final out = <String, (String, String, bool)>{};
    for (final g in routine) {
      for (final slot in g.slots) {
        final key = courseKey(slot.courseCode);
        if (key.isEmpty || have.contains(key) || g.hides(slot.courseCode)) {
          continue;
        }
        final prev = out[key];
        final labOnly = (prev?.$3 ?? true) && slot.kind == ClassKind.lab;
        out[key] = (
          prev?.$1 ?? slot.courseCode,
          (prev?.$2.isNotEmpty ?? false) ? prev!.$2 : slot.courseTitle,
          labOnly,
        );
      }
    }
    return [
      for (final (code, title, lab) in out.values)
        (code, title, lab ? 1.5 : 3.0),
    ];
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.course,
    required this.grade,
    required this.replaced,
    required this.onTap,
  });

  final CgpaCourse course;
  final Grade? grade;
  final bool replaced;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parts = [
      if (course.code.isNotEmpty && course.title.isNotEmpty) course.title,
      l10n.cgpaCredits(creditsText(context, course.credits)),
      if (replaced) l10n.cgpaNotCounted,
    ];
    return CsRow(
      icon: CsIcons.course,
      title: course.label,
      subtitle: parts.join(' · '),
      showChevron: false,
      onTap: onTap,
      trailing: grade == null
          ? Text('–', style: context.text.titleMedium)
          : CsBadge(
              label: grade!.letter,
              tone: grade!.points == 0
                  ? CsBadgeTone.danger
                  : replaced
                  ? CsBadgeTone.neutral
                  : CsBadgeTone.primary,
            ),
    );
  }
}

/// Adds or edits a course of a semester.
Future<void> showCourseSheet(
  BuildContext context,
  CgpaCubit cubit,
  String semesterId,
  GradeScale scale, {
  CgpaCourse? course,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _CourseSheet(
    cubit: cubit,
    semesterId: semesterId,
    scale: scale,
    course: course,
  ),
);

class _CourseSheet extends StatefulWidget {
  const _CourseSheet({
    required this.cubit,
    required this.semesterId,
    required this.scale,
    this.course,
  });

  final CgpaCubit cubit;
  final String semesterId;
  final GradeScale scale;
  final CgpaCourse? course;

  @override
  State<_CourseSheet> createState() => _CourseSheetState();
}

class _CourseSheetState extends State<_CourseSheet> {
  late final _code = TextEditingController(text: widget.course?.code ?? '');
  late final _title = TextEditingController(text: widget.course?.title ?? '');
  late final _credits = TextEditingController(
    text: _plain(widget.course?.credits ?? 3),
  );
  late final _marks = TextEditingController(
    text: widget.course?.marks == null ? '' : _plain(widget.course!.marks!),
  );
  late bool _byMarks = widget.course?.marks != null;
  late String? _letter = widget.course?.letter;
  String? _error;

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _credits.dispose();
    _marks.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final credits = parseNumber(_credits.text);
    final marks = parseNumber(_marks.text);
    String? error;
    if (_code.text.trim().isEmpty && _title.text.trim().isEmpty) {
      error = l10n.cgpaCodeRequired;
    } else if (credits == null || credits < 0.5 || credits > 6) {
      error = l10n.cgpaCreditsInvalid;
    } else if (_byMarks &&
        _marks.text.trim().isNotEmpty &&
        (marks == null || marks < 0 || marks > 100)) {
      error = l10n.cgpaMarksInvalid;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final c = CgpaCourse(
      id: widget.course?.id ?? widget.cubit.newId(),
      code: _code.text.trim().toUpperCase(),
      title: _title.text.trim(),
      credits: credits!,
      letter: _byMarks ? null : _letter,
      marks: _byMarks ? marks : null,
    );
    widget.cubit.saveCourse(widget.semesterId, c);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final marks = parseNumber(_marks.text);
    final fromMarks = marks == null ? null : widget.scale.forMarks(marks);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            0,
            CsSpace.lg,
            CsSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.course == null
                          ? l10n.cgpaAddCourse
                          : l10n.cgpaEditCourse,
                      style: context.text.titleLarge,
                    ),
                  ),
                  if (widget.course != null)
                    IconButton(
                      tooltip: l10n.deleteAction,
                      color: cs.error,
                      icon: const Icon(CsIcons.delete),
                      onPressed: () {
                        widget.cubit.deleteCourse(
                          widget.semesterId,
                          widget.course!.id,
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: CsSpace.md),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 20,
                      decoration: InputDecoration(
                        labelText: l10n.cgpaCourseCode,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _credits,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.cgpaCreditsLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.sm),
              TextField(
                controller: _title,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.cgpaCourseTitle,
                  counterText: '',
                ),
              ),
              const SizedBox(height: CsSpace.md),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.cgpaGradeLetter),
                  ),
                  ButtonSegment(value: true, label: Text(l10n.cgpaGradeMarks)),
                ],
                selected: {_byMarks},
                onSelectionChanged: (v) => setState(() => _byMarks = v.first),
              ),
              const SizedBox(height: CsSpace.md),
              if (_byMarks) ...[
                TextField(
                  controller: _marks,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.cgpaMarksLabel),
                  onChanged: (_) => setState(() {}),
                ),
                if (fromMarks != null) ...[
                  const SizedBox(height: CsSpace.xs),
                  Text(
                    l10n.cgpaMarksGives(
                      fromMarks.letter,
                      gpaText(context, fromMarks.points),
                    ),
                    style: context.text.bodyMedium?.copyWith(color: cs.primary),
                  ),
                ],
              ] else
                Wrap(
                  spacing: CsSpace.sm,
                  runSpacing: CsSpace.sm,
                  children: [
                    for (final g in widget.scale.grades)
                      ChoiceChip(
                        label: Text(g.letter),
                        selected: _letter == g.letter,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _letter = g.letter),
                      ),
                    ChoiceChip(
                      label: Text(l10n.cgpaNotGraded),
                      selected: _letter == null,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _letter = null),
                    ),
                  ],
                ),
              if (_error != null) ...[
                const SizedBox(height: CsSpace.md),
                Text(
                  _error!,
                  style: context.text.bodyMedium?.copyWith(color: cs.error),
                ),
              ],
              const SizedBox(height: CsSpace.lg),
              FilledButton(onPressed: _save, child: Text(l10n.cgpaSave)),
            ],
          ),
        ),
      ),
    );
  }
}
