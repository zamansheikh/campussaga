import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/clock.dart';
import '../../../app/router.dart';
import '../../classes/presentation/bloc/my_classes_cubit.dart';
import '../../classes/presentation/class_format.dart';
import '../../classes/presentation/widgets/class_sheet.dart';
import '../../classes/presentation/widgets/class_tile.dart';

/// The icon of a kind of test or deadline.
IconData assessmentIcon(AssessmentKind k) => switch (k) {
  AssessmentKind.classTest || AssessmentKind.quiz => Icons.quiz_outlined,
  AssessmentKind.assignment => Icons.assignment_outlined,
  AssessmentKind.labReport => Icons.science_outlined,
  AssessmentKind.presentation => Icons.co_present_outlined,
  AssessmentKind.midterm || AssessmentKind.finalExam => Icons.edit_document,
  AssessmentKind.other => Icons.event_note_outlined,
};

/// "Class test · CSE 101".
String assessmentTitle(AppLocalizations l10n, Assessment a) =>
    '${assessmentKindText(l10n, a.kind)} · ${a.courseCode}';

/// One test or deadline in a list: what, which course, when and where.
class AssessmentTile extends StatelessWidget {
  const AssessmentTile({
    super.key,
    required this.assessment,
    required this.group,
    required this.now,
    this.showGroup = false,
  });

  final Assessment assessment;
  final ClassGroup group;
  final DateTime now;
  final bool showGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final a = assessment;
    final when = dayText(context, a.date, now);
    final today = DateTime(now.year, now.month, now.day);
    final soon = !a.date.isAfter(today.add(const Duration(days: 1)));
    final meta = [
      assessmentTimeText(context, a),
      if (a.room.isNotEmpty) l10n.roomShort(a.room),
      if (showGroup) group.title,
    ].where((x) => x.isNotEmpty).join(' · ');
    return InkWell(
      onTap: () => showAssessmentSheet(context, a, group),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CsSpace.md,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: courseColor(a.courseCode).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(CsRadius.md),
              ),
              child: Icon(
                assessmentIcon(a.kind),
                color: courseColor(a.courseCode),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        assessmentTitle(l10n, a),
                        style: context.text.titleSmall,
                      ),
                      CsBadge(
                        label: when,
                        tone: soon ? CsBadgeTone.accent : CsBadgeTone.neutral,
                      ),
                    ],
                  ),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (a.topics.isNotEmpty)
                    Text(
                      a.topics,
                      style: context.text.bodySmall?.copyWith(
                        color: cs.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today: tests and deadlines in the next 7 days.
class ComingUpSection extends StatelessWidget {
  const ComingUpSection({super.key, required this.groups, required this.now});

  final List<ClassGroup> groups;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final items = upcomingAssessments(groups, now);
    if (items.isEmpty) return const SizedBox.shrink();
    final many = groups.where((g) => !g.isPersonal).length > 1;
    return Padding(
      padding: const EdgeInsets.only(top: CsSpace.lg),
      child: CsSection(
        title: AppLocalizations.of(context).comingUp,
        children: [
          for (final x in items)
            AssessmentTile(
              assessment: x.assessment,
              group: x.group,
              now: now,
              showGroup: many,
            ),
        ],
      ),
    );
  }
}

/// Details of a test or deadline; edit and delete for who added it or a CR.
Future<void> showAssessmentSheet(
  BuildContext context,
  Assessment a,
  ClassGroup group,
) {
  final cubit = context.read<MyClassesCubit>();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _AssessmentSheet(assessment: a, group: group, host: context),
    ),
  );
}

class _AssessmentSheet extends StatelessWidget {
  const _AssessmentSheet({
    required this.assessment,
    required this.group,
    required this.host,
  });

  final Assessment assessment;
  final ClassGroup group;

  /// The page under the sheet: actions continue there after it closes.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final a = assessment;
    final time = assessmentTimeText(context, a);

    void close(void Function() then) {
      Navigator.of(context).pop();
      then();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.lg,
          0,
          CsSpace.lg,
          CsSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(assessmentIcon(a.kind), color: courseColor(a.courseCode)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    assessmentKindText(l10n, a.kind),
                    style: context.text.labelLarge?.copyWith(
                      color: cs.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.xs),
            Text(a.courseCode, style: context.text.titleLarge),
            if (a.courseTitle.isNotEmpty)
              Text(a.courseTitle, style: context.text.bodyMedium),
            const SizedBox(height: CsSpace.md),
            _Line(Icons.event_outlined, dateText(context, a.date)),
            if (time.isNotEmpty) _Line(Icons.access_time_rounded, time),
            if (a.room.isNotEmpty)
              _Line(Icons.meeting_room_outlined, l10n.roomShort(a.room)),
            _Line(Icons.groups_outlined, group.title),
            if ((a.createdByName ?? '').isNotEmpty)
              _Line(
                Icons.person_outline_rounded,
                l10n.addedBy(a.createdByName!),
              ),
            if (a.topics.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: CsSpace.sm),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(CsRadius.md),
                ),
                child: Text(a.topics, style: context.text.bodyMedium),
              ),
            const SizedBox(height: CsSpace.md),
            if (a.canEdit)
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => close(
                        () => host.push(Routes.editTest(group.id, a.id)),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.editAction),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      onPressed: () =>
                          close(() => deleteAssessment(host, a, group.id)),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.deleteAction),
                    ),
                  ),
                ],
              )
            else
              Text(
                l10n.testOnlyOwnerHint,
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// Asks, then deletes a test or deadline for everyone.
Future<void> deleteAssessment(
  BuildContext context,
  Assessment a,
  String groupId,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(
        l10n.deleteTestTitle(assessmentKindText(l10n, a.kind).toLowerCase()),
      ),
      content: Text(l10n.deleteTestBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: dialog.cs.error),
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(l10n.deleteAction),
        ),
      ],
    ),
  );
  if (!(ok ?? false) || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await context.read<MyClassesCubit>().deleteAssessment(groupId, a.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.testDeleted)));
  } on Failure catch (f) {
    messenger.showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
  }
}

/// The tests and deadlines of [group] from today on (group page).
class GroupAssessments extends StatelessWidget {
  const GroupAssessments({super.key, required this.group});

  final ClassGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = appNow();
    final today = DateTime(now.year, now.month, now.day);
    final list = [
      for (final a in group.assessments)
        if (!a.date.isBefore(today)) a,
    ];
    return CsSection(
      title: l10n.testsAndDeadlines,
      children: [
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(CsSpace.md),
            child: Text(l10n.noTestsYet, style: context.text.bodyMedium),
          ),
        for (final a in list)
          AssessmentTile(assessment: a, group: group, now: now),
        CsRow(
          icon: Icons.add_rounded,
          title: l10n.addTest,
          onTap: () => context.push(Routes.newTest(group.id)),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.cs.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}
