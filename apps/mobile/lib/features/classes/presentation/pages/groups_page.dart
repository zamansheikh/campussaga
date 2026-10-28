import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/my_classes_cubit.dart';

/// The student's class groups, and ways to join or create one.
class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = context.select((MyClassesCubit c) => c.state.groups);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.classGroups),
        actions: [
          IconButton(
            tooltip: l10n.findClass,
            icon: const Icon(CsIcons.search),
            onPressed: () => context.push(Routes.findClass),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<MyClassesCubit>().refresh,
        child: CsPage(
          children: [
            if (groups.isNotEmpty) ...[
              CsSection(
                children: [
                  for (final g in groups)
                    _GroupRow(
                      group: g,
                      onTap: () => context.push(Routes.group(g.id)),
                    ),
                ],
              ),
              const SizedBox(height: CsSpace.lg),
            ],
            const JoinOrCreate(),
          ],
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.onTap});

  final ClassGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CsRow(
      icon: CsIcons.groups,
      title: group.title,
      subtitle: [
        group.semester,
        l10n.classesCount(group.slots.length),
      ].join(' · '),
      trailing: group.isCr
          ? CsBadge(label: l10n.roleCr, tone: CsBadgeTone.success)
          : null,
      onTap: onTap,
    );
  }
}

/// "Find your class", "Join with a code" and "I'm the CR" buttons.
class JoinOrCreate extends StatelessWidget {
  const JoinOrCreate({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => context.push(Routes.findClass),
          icon: const Icon(CsIcons.search),
          label: Text(l10n.findClass),
        ),
        const SizedBox(height: CsSpace.sm),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.joinGroup),
          icon: const Icon(CsIcons.key),
          label: Text(l10n.joinWithCode),
        ),
        const SizedBox(height: CsSpace.sm),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.newGroup),
          icon: const Icon(CsIcons.add),
          label: Text(l10n.imTheCr),
        ),
        const SizedBox(height: CsSpace.sm),
        Text(
          l10n.createGroupHint,
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}
