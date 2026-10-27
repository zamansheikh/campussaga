import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';
import '../widgets/class_tile.dart';

enum _Action { edit, leave, delete }

/// One group: invite code and the weekly routine. The CR edits it here.
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

    final days = [
      for (final d in weekOrder)
        (
          d,
          [
            for (final s in g.slots)
              if (s.weekday == d) s,
          ],
        ),
    ].where((e) => e.$2.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(g.title),
        actions: [
          PopupMenuButton<_Action>(
            onSelected: (a) => _act(context, g, a),
            itemBuilder: (context) => [
              if (g.isCr)
                PopupMenuItem(value: _Action.edit, child: Text(l10n.editGroup)),
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
              icon: const Icon(Icons.add_rounded),
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
            const SizedBox(height: CsSpace.md),
            _InviteCard(group: g),
            const SizedBox(height: CsSpace.lg),
            if (days.isEmpty)
              _EmptyRoutine(group: g)
            else
              for (final (day, slots) in days) ...[
                CsSection(
                  title: weekdayName(context, day),
                  children: [
                    for (final s in slots)
                      ClassTile(
                        slot: s,
                        onTap: g.isCr
                            ? () => context.push(Routes.editSlot(g.id, s.id))
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: CsSpace.lg),
              ],
          ],
        ),
      ),
    );
  }
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
          child: Icon(Icons.groups_rounded, color: cs.onPrimaryContainer),
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
            icon: Icons.star_rounded,
            tone: CsBadgeTone.success,
          ),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.group});

  final ClassGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CsSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.inviteTitle, style: context.text.titleSmall),
            Text(l10n.inviteHint, style: context.text.bodySmall),
            const SizedBox(height: CsSpace.md),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(CsRadius.md),
                    ),
                    child: SelectableText(
                      group.joinCode,
                      style: context.text.headlineSmall?.copyWith(
                        letterSpacing: 6,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                IconButton.filledTonal(
                  tooltip: l10n.copyInvite,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: l10n.inviteMessage(
                          group.title,
                          l10n.appName,
                          group.joinCode,
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.inviteCopied)),
                      );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
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
          icon: Icons.event_note_rounded,
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
