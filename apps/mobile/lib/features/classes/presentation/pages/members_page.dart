import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

enum _Action { makeCr, makeMember, remove }

/// The group's students, for CRs: give the CR role to up to 2 more
/// classmates, step down, or remove someone who isn't in the section.
class MembersPage extends StatefulWidget {
  const MembersPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<GroupMember>? _members;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await context.read<MyClassesCubit>().members(widget.groupId);
      if (mounted) setState(() => _members = m);
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    }
  }

  Future<void> _act(GroupMember m, _Action a) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyClassesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final name = m.name.isEmpty ? l10n.unnamedStudent : m.name;
    if (a == _Action.remove) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.removeMemberTitle(name)),
          content: Text(l10n.removeMemberBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: dialog.cs.error),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.removeFromGroup),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    try {
      switch (a) {
        case _Action.makeCr:
          await cubit.setMemberRole(widget.groupId, m.userId, GroupRole.cr);
        case _Action.makeMember:
          await cubit.setMemberRole(widget.groupId, m.userId, GroupRole.member);
        case _Action.remove:
          await cubit.removeMember(widget.groupId, m.userId);
      }
      // Stepped down: no longer allowed to see this list.
      if (m.isMe && a == _Action.makeMember) {
        if (mounted) context.pop();
        return;
      }
      await _load();
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = _members;
    final crs = members?.where((m) => m.role == GroupRole.cr).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.members)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CsPage(
          children: [
            Text(
              l10n.crHint,
              style: context.text.bodyMedium?.copyWith(
                color: context.cs.textSecondary,
              ),
            ),
            const SizedBox(height: CsSpace.lg),
            if (_failure != null)
              Text(classErrorText(l10n, _failure!))
            else if (members == null)
              const Center(child: CircularProgressIndicator())
            else
              CsSection(
                title: l10n.membersCount(members.length),
                children: [
                  for (final m in members)
                    _MemberRow(
                      member: m,
                      actions: [
                        if (m.role == GroupRole.member) _Action.makeCr,
                        if (m.role == GroupRole.cr && crs > 1)
                          _Action.makeMember,
                        if (m.role == GroupRole.member && !m.isMe)
                          _Action.remove,
                      ],
                      onAction: (a) => _act(m, a),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.actions,
    required this.onAction,
  });

  final GroupMember member;
  final List<_Action> actions;
  final ValueChanged<_Action> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = member.name.isEmpty ? l10n.unnamedStudent : member.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CsSpace.md, 10, CsSpace.xs, 10),
      child: Row(
        children: [
          CsAvatar(name: name, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(name, style: context.text.bodyLarge),
                if (member.role == GroupRole.cr)
                  CsBadge(label: l10n.roleCr, tone: CsBadgeTone.success),
                if (member.isMe)
                  CsBadge(label: l10n.youLabel, tone: CsBadgeTone.neutral),
              ],
            ),
          ),
          if (actions.isEmpty)
            const SizedBox(width: 48)
          else
            PopupMenuButton<_Action>(
              onSelected: onAction,
              itemBuilder: (context) => [
                for (final a in actions)
                  PopupMenuItem(
                    value: a,
                    child: Text(
                      switch (a) {
                        _Action.makeCr => l10n.makeCr,
                        _Action.makeMember =>
                          member.isMe ? l10n.stepDown : l10n.makeMember,
                        _Action.remove => l10n.removeFromGroup,
                      },
                      style: a == _Action.remove
                          ? TextStyle(color: context.cs.error)
                          : null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
