import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/clock.dart';
import '../../../../app/router.dart';
import '../../../announcements/presentation/announcement_widgets.dart';
import '../../../announcements/presentation/seen_cubit.dart';
import '../../../assessments/presentation/assessment_widgets.dart';
import '../../../growth/presentation/invite_share.dart';
import '../../data/invite_link.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';
import '../widgets/class_sheet.dart';
import '../widgets/class_tile.dart';

enum _Action { edit, semester, leave, delete }

/// One group: its next seven days of classes first (tap a class for its
/// actions on that day), then tests, announcements and later changes; the
/// invite code is a compact bar, courses and members at the end.
class GroupPage extends StatelessWidget {
  const GroupPage({super.key, required this.groupId});

  final String groupId;

  Future<void> _act(BuildContext context, ClassGroup g, _Action a) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyClassesCubit>();
    if (a == _Action.edit) {
      await context.push(Routes.editGroup(g.id));
      return;
    }
    if (a == _Action.semester) {
      final semester = await showDialog<String>(
        context: context,
        builder: (_) => _NewSemesterDialog(current: g.semester),
      );
      if (semester == null || !context.mounted) return;
      try {
        await cubit.newSemester(g.id, semester);
      } on Failure catch (f) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
      }
      return;
    }
    final leaving = a == _Action.leave;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(leaving ? l10n.leaveGroupTitle : l10n.deleteGroupTitle),
        content: Text(leaving ? l10n.leaveGroupBody : l10n.deleteGroupBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.cs.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(leaving ? l10n.leaveGroup : l10n.deleteGroup),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !context.mounted) return;
    try {
      await (leaving ? cubit.leave(g.id) : cubit.delete(g.id));
      if (context.mounted) context.pop();
    } on Failure catch (f) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = context.select((MyClassesCubit c) => c.state.group(groupId));
    if (g == null) return const Scaffold(body: SizedBox.shrink());
    // Opening the group shows its announcements: they're no longer new.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.read<SeenCubit>().markSeen(g);
    });

    final today = DateUtils.dateOnly(appNow());
    // The group's whole routine, also courses this student hides from
    // their own (Today and Routine leave those out).
    final all = g.copyWith(hiddenCourses: const {});
    final week = [
      for (var i = 0; i < 7; i++)
        (
          DateUtils.addDaysToDate(today, i),
          classesOn([all], DateUtils.addDaysToDate(today, i)),
        ),
    ].where((e) => e.$2.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(g.title),
        actions: [
          PopupMenuButton<_Action>(
            icon: const Icon(CsIcons.more),
            onSelected: (a) => _act(context, g, a),
            itemBuilder: (context) => [
              if (g.isCr)
                PopupMenuItem(value: _Action.edit, child: Text(l10n.editGroup)),
              if (g.isCr)
                PopupMenuItem(
                  value: _Action.semester,
                  child: Text(l10n.newSemester),
                ),
              PopupMenuItem(value: _Action.leave, child: Text(l10n.leaveGroup)),
              if (g.isCr)
                PopupMenuItem(
                  value: _Action.delete,
                  child: Text(
                    l10n.deleteGroup,
                    style: TextStyle(color: context.cs.error),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: g.isCr && g.slots.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newSlot(g.id)),
              icon: const Icon(CsIcons.add),
              label: Text(l10n.addClass),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: context.read<MyClassesCubit>().refresh,
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.screen,
            CsSpace.sm,
            CsSpace.screen,
            96, // room for the button
          ),
          children: [
            _Header(group: g),
            const SizedBox(height: CsSpace.sm),
            _InviteBar(group: g),
            const SizedBox(height: CsSpace.lg),
            if (g.slots.isEmpty)
              _EmptyRoutine(group: g)
            else
              for (final (date, items) in week) ...[
                CsSection(
                  title: _dayTitle(context, date, today),
                  children: [
                    for (final i in items)
                      ClassTile.on(i, onTap: () => showClassSheet(context, i)),
                  ],
                ),
                const SizedBox(height: CsSpace.lg),
              ],
            GroupAssessments(group: g),
            const SizedBox(height: CsSpace.lg),
            AnnouncementsSection(group: g),
            const SizedBox(height: CsSpace.lg),
            ..._laterChanges(context, g, today),
            CsSection(
              children: [
                if (g.slots.isNotEmpty)
                  CsRow(
                    icon: CsIcons.myCourses,
                    title: l10n.myCourses,
                    subtitle: _coursesShown(l10n, g),
                    onTap: () => context.push(Routes.groupCourses(g.id)),
                  ),
                if (g.isCr)
                  CsRow(
                    icon: CsIcons.members,
                    title: l10n.members,
                    subtitle: l10n.membersCount(g.memberCount),
                    onTap: () => context.push(Routes.groupMembers(g.id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _coursesShown(AppLocalizations l10n, ClassGroup g) {
  final all = {for (final s in g.slots) courseKey(s.courseCode)};
  return l10n.coursesShown(
    all.where((c) => !g.hiddenCourses.contains(c)).length,
    all.length,
  );
}

/// Asks for the new semester's name ("Spring 2027").
class _NewSemesterDialog extends StatefulWidget {
  const _NewSemesterDialog({required this.current});

  final String current;

  @override
  State<_NewSemesterDialog> createState() => _NewSemesterDialogState();
}

class _NewSemesterDialogState extends State<_NewSemesterDialog> {
  late final _name = TextEditingController(text: _next(widget.current));

  /// "Fall 2026" -> "Spring 2027", "Spring 2027" -> "Summer 2027", ...
  static String _next(String current) {
    const terms = ['Spring', 'Summer', 'Fall'];
    final m = RegExp(r'^(Spring|Summer|Fall)\s+(\d{4})$').firstMatch(current);
    if (m == null) return '';
    final i = terms.indexOf(m[1]!);
    final year = int.parse(m[2]!) + (i == 2 ? 1 : 0);
    return '${terms[(i + 1) % 3]} $year';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.newSemester),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.newSemesterBody),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.semesterLabel,
                hintText: l10n.semesterHint,
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
        TextButton(
          onPressed: () {
            final v = _name.text.trim();
            if (v.isNotEmpty) Navigator.of(context).pop(v);
          },
          child: Text(l10n.startAction),
        ),
      ],
    );
  }
}

/// "Today · Wednesday, October 28", "Tomorrow · …", or the date.
String _dayTitle(BuildContext context, DateTime date, DateTime today) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final text = DateFormat.MMMMEEEEd(locale).format(date);
  if (date == today) return '${l10n.dayToday} · $text';
  if (date == DateUtils.addDaysToDate(today, 1)) {
    return '${l10n.dayTomorrow} · $text';
  }
  return text;
}

/// Changes after this week (this week's are in the days above), each shown
/// as the class on its date.
List<Widget> _laterChanges(BuildContext context, ClassGroup g, DateTime today) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final weekEnd = DateUtils.addDaysToDate(today, 7);
  final items = [
    for (final c in g.changes)
      for (final d in {c.date, ?c.newDate})
        if (!d.isBefore(weekEnd))
          ...classesOn([g], d).where((i) => i.change?.id == c.id),
  ];
  if (items.isEmpty) return const [];
  return [
    CsSection(
      title: l10n.upcomingChanges,
      children: [
        for (final i in items)
          ClassTile.on(
            i,
            overline: DateFormat.MMMMEEEEd(locale).format(i.date),
            onTap: () => showClassSheet(context, i),
          ),
      ],
    ),
    const SizedBox(height: CsSpace.lg),
  ];
}

class _Header extends StatelessWidget {
  const _Header({required this.group});

  final ClassGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(CsRadius.md),
          ),
          child: Icon(CsIcons.groups, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: CsSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.semester, style: context.text.titleMedium),
              Text(
                [
                  l10n.membersCount(group.memberCount),
                  l10n.classesCount(group.slots.length),
                ].join(' · '),
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
        if (group.isCr)
          CsBadge(
            label: l10n.roleCr,
            icon: CsIcons.star,
            tone: CsBadgeTone.success,
          ),
      ],
    );
  }
}

/// The join code on one line, with a copy-invite button.
class _InviteBar extends StatelessWidget {
  const _InviteBar({required this.group});

  final ClassGroup group;

  /// The invite: the link (opens the app, or the page with Google Play),
  /// and the code for anyone joining by hand.
  /// [ref] is my own invite code: a friend who joins through the link
  /// counts as my invite.
  String _message(AppLocalizations l10n, String? ref) => l10n.inviteMessage(
    group.title,
    l10n.appName,
    InviteLink.link(group.joinCode, ref: ref).toString(),
    group.joinCode,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(CsSpace.md, 4, 4, 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(CsRadius.md),
        border: Border.all(color: cs.border),
      ),
      child: Row(
        children: [
          Icon(CsIcons.invite, size: 18, color: cs.textSecondary),
          const SizedBox(width: CsSpace.sm),
          Expanded(
            child: Text(
              l10n.inviteTitle,
              style: context.text.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SelectableText(
            group.joinCode,
            style: context.text.titleMedium?.copyWith(
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          IconButton(
            tooltip: l10n.copyInvite,
            onPressed: () async {
              final ref = await myReferralCode(context);
              await Clipboard.setData(ClipboardData(text: _message(l10n, ref)));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l10n.inviteCopied)));
            },
            icon: const Icon(CsIcons.copy, size: 20),
          ),
          IconButton(
            tooltip: l10n.shareInvite,
            onPressed: () async {
              final box = context.findRenderObject() as RenderBox?;
              final ref = await myReferralCode(context);
              await SharePlus.instance.share(
                ShareParams(
                  text: _message(l10n, ref),
                  subject: group.title,
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                ),
              );
            },
            icon: const Icon(CsIcons.send, size: 20),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutine extends StatelessWidget {
  const _EmptyRoutine({required this.group});

  final ClassGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CsSpace.md),
        child: CsEmptyState(
          icon: CsIcons.routineNote,
          title: l10n.weeklyRoutine,
          message: group.isCr ? l10n.noClassesYetCr : l10n.noClassesYetMember,
          actionLabel: group.isCr ? l10n.addClass : null,
          onAction: group.isCr
              ? () => context.push(Routes.newSlot(group.id))
              : null,
        ),
      ),
    );
  }
}
