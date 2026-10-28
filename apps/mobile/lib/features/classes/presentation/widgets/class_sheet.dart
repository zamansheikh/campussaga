import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/clock.dart';
import '../../../../app/router.dart';
import '../../../assessments/presentation/assessment_widgets.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';
import 'class_tile.dart';

String dateText(BuildContext context, DateTime d) =>
    DateFormat.MMMMEEEEd(Localizations.localeOf(context).toLanguageTag())
        .format(d);

/// Details of one class on one date. The CR can cancel it, change its time
/// or room for that date, undo a change, or edit the weekly class.
Future<void> showClassSheet(BuildContext context, ClassOnDay item) {
  final cubit = context.read<MyClassesCubit>();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheet) => BlocProvider.value(
      value: cubit,
      child: _ClassSheet(item: item, host: context),
    ),
  );
}

class _ClassSheet extends StatelessWidget {
  const _ClassSheet({required this.item, required this.host});

  final ClassOnDay item;

  /// The page under the sheet: actions continue there after it closes.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final s = item.slot;
    final today = DateUtils.dateOnly(appNow());
    final personal = item.group.isPersonal;
    final canChange =
        item.group.isCr && !personal && !item.date.isBefore(today);
    // The class's own date (a class moved here keeps its original date).
    final ownDate = item.movedFrom ?? item.date;
    final movedTo = item.movedTo;
    final tests = personal
        ? const <Assessment>[]
        : item.group.assessmentsOn(item.date, s.courseCode);

    void close(void Function() then) {
      Navigator.of(context).pop();
      then();
    }

    final timeText = rangeText(
      context,
      ClassSlot(
        id: s.id,
        courseCode: s.courseCode,
        weekday: s.weekday,
        startMin: item.startMin,
        endMin: item.endMin,
      ),
    );

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
                Container(
                  width: 6,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: courseColor(s.courseCode),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.courseCode, style: context.text.titleLarge),
                      if (s.courseTitle.isNotEmpty)
                        Text(s.courseTitle, style: context.text.bodyMedium),
                    ],
                  ),
                ),
                if (item.cancelled)
                  CsBadge(label: l10n.changeCancelled, tone: CsBadgeTone.danger)
                else if (movedTo != null || item.movedFrom != null)
                  CsBadge(label: l10n.changeMoved, tone: CsBadgeTone.accent)
                else if (item.moved)
                  CsBadge(label: l10n.changeMoved, tone: CsBadgeTone.accent)
                else if (item.extra)
                  CsBadge(label: l10n.changeExtra),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            _Line(Icons.event_outlined, dateText(context, item.date)),
            if (movedTo != null)
              _Line(
                Icons.east_rounded,
                l10n.movedToDay(
                  '${dateText(context, movedTo)}, '
                  '${rangeText(context, ClassSlot(id: s.id, courseCode: s.courseCode, weekday: movedTo.weekday, startMin: item.change!.startMin!, endMin: item.change!.endMin!))}',
                ),
                strong: true,
              ),
            if (item.movedFrom != null)
              _Line(
                Icons.west_rounded,
                l10n.movedFromDay(dateText(context, item.movedFrom!)),
                strong: true,
              ),
            _Line(
              Icons.access_time_rounded,
              item.timeChanged
                  ? '$timeText  (${l10n.wasTime(clockText(context, s.startMin))})'
                  : timeText,
            ),
            if (item.room.isNotEmpty)
              _Line(
                Icons.meeting_room_outlined,
                item.roomChanged && s.room.isNotEmpty
                    ? '${l10n.roomShort(item.room)}  (${l10n.wasTime(s.room)})'
                    : l10n.roomShort(item.room),
              ),
            if (s.teacher.isNotEmpty)
              _Line(Icons.person_outline_rounded, s.teacher),
            if (!personal) _Line(Icons.groups_outlined, item.group.title),
            if ((item.change?.note ?? '').isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: CsSpace.sm),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(CsRadius.md),
                ),
                child: Text(item.change!.note, style: context.text.bodyMedium),
              ),
            if (tests.isNotEmpty) ...[
              const SizedBox(height: CsSpace.sm),
              for (final t in tests)
                _TestChip(
                  test: t,
                  onTap: () =>
                      close(() => showAssessmentSheet(host, t, item.group)),
                ),
            ],
            const SizedBox(height: CsSpace.md),
            if (canChange && !item.extra && !item.cancelled) ...[
              OutlinedButton.icon(
                onPressed: () => close(
                  () => host.push(
                    Routes.changeClass(item.group.id, s.id, ownDate),
                  ),
                ),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(l10n.changeTimeOrRoom),
              ),
              const SizedBox(height: CsSpace.sm),
              if (movedTo == null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                  onPressed: () => close(() => confirmCancel(host, item)),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(l10n.cancelThisClass),
                ),
                const SizedBox(height: CsSpace.sm),
              ],
            ],
            if (canChange && item.change != null) ...[
              OutlinedButton.icon(
                onPressed: () => close(() => _undo(host, item)),
                icon: const Icon(Icons.undo_rounded),
                label: Text(
                  item.extra ? l10n.removeExtraClass : l10n.undoChange,
                ),
              ),
              const SizedBox(height: CsSpace.sm),
            ],
            if (personal)
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () =>
                          close(() => host.push(Routes.editPersonal(s.id))),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.editAction),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      onPressed: () => close(() => _deletePersonal(host, s)),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.deleteAction),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  if (!item.date.isBefore(today) && !item.off)
                    Expanded(
                      child: TextButton(
                        onPressed: () => close(
                          () => host.push(
                            Routes.newTest(
                              item.group.id,
                              course: s.courseCode,
                              date: item.date,
                            ),
                          ),
                        ),
                        child: Text(l10n.addTest, textAlign: TextAlign.center),
                      ),
                    ),
                  if (item.group.isCr && !item.extra)
                    Expanded(
                      child: TextButton(
                        onPressed: () => close(
                          () => host.push(Routes.editSlot(item.group.id, s.id)),
                        ),
                        child: Text(l10n.editWeeklyClass),
                      ),
                    ),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          close(() => host.push(Routes.group(item.group.id))),
                      child: Text(l10n.openGroupAction),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _deletePersonal(BuildContext context, ClassSlot s) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.deletePersonalTitle),
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
      await context.read<MyClassesCubit>().deleteSlot(personalGroupId, s.id);
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
    }
  }

  static Future<void> _undo(BuildContext context, ClassOnDay item) => runChange(
    context,
    () => context.read<MyClassesCubit>().deleteChange(
      item.group.id,
      item.change!.id,
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text, {this.strong = false});

  final IconData icon;
  final String text;

  /// Highlighted (where a moved class went or came from).
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = strong ? context.cs.statusInProgress.fg : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? context.cs.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium?.copyWith(
                color: color,
                fontWeight: strong ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A test or deadline of this class on this day.
class _TestChip extends StatelessWidget {
  const _TestChip({required this.test, required this.onTap});

  final Assessment test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final time = assessmentTimeText(context, test);
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.xs),
      child: Material(
        color: cs.statusRejected.bg,
        borderRadius: BorderRadius.circular(CsRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(assessmentIcon(test.kind), color: cs.statusRejected.fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    [
                      assessmentKindText(l10n, test.kind),
                      if (time.isNotEmpty) time,
                      if (test.topics.isNotEmpty) test.topics,
                    ].join(' · '),
                    style: context.text.bodyMedium?.copyWith(
                      color: cs.statusRejected.fg,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.statusRejected.fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks to cancel [item] on its date, with an optional note.
Future<void> confirmCancel(BuildContext context, ClassOnDay item) async {
  final note = await showDialog<String>(
    context: context,
    builder: (_) => _CancelDialog(item: item),
  );
  if (note == null || !context.mounted) return;
  await runChange(
    context,
    () => context.read<MyClassesCubit>().addChange(
      item.group.id,
      ChangeDraft.cancel(
        slotId: item.slot.id,
        date: item.movedFrom ?? item.date,
        note: note,
      ),
    ),
  );
}

/// Returns the note ('' for none) when confirmed, null when kept.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.item});

  final ClassOnDay item;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    return AlertDialog(
      title: Text(
        l10n.cancelClassTitle(
          item.slot.courseCode,
          dateText(context, item.date),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.cancelClassBody),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _note,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                hintText: l10n.noteHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.keepClass),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: context.cs.error),
          onPressed: () => Navigator.of(context).pop(_note.text.trim()),
          child: Text(l10n.confirmCancel),
        ),
      ],
    );
  }
}

/// Runs a change and tells the CR how it went.
Future<void> runChange(BuildContext context, Future<void> Function() fn) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await fn();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.changeSaved)));
  } on Failure catch (f) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
  }
}
