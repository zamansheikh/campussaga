import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/widgets/notice_banner.dart';
import '../../classes/presentation/bloc/my_classes_cubit.dart';
import 'bloc/reminders_cubit.dart';

/// Reminders on/off, how early, and which courses.
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RemindersCubit>();
    final state = context.watch<RemindersCubit>().state;
    final s = state.settings;
    final groups = context.select((MyClassesCubit c) => c.state.groups);

    // Each course once, by course code.
    final courses = <String, ClassSlot>{};
    for (final g in groups) {
      for (final slot in g.slots) {
        courses.putIfAbsent(
          ReminderSettings.courseKey(slot.courseCode),
          () => slot,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminders)),
      body: CsPage(
        children: [
          CsSection(
            children: [
              CsRow(
                icon: Icons.notifications_active_outlined,
                title: l10n.remindersSwitch,
                subtitle: l10n.remindersSwitchHint,
                showChevron: false,
                trailing: Switch(
                  value: state.active,
                  onChanged: (on) => on ? cubit.enable() : cubit.disable(),
                ),
                onTap: () => state.active ? cubit.disable() : cubit.enable(),
              ),
            ],
          ),
          if (state.permissionDenied) ...[
            const SizedBox(height: CsSpace.md),
            NoticeBanner(text: l10n.notificationsBlocked),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: cubit.enable,
                child: Text(l10n.tryAgain),
              ),
            ),
          ],
          if (state.active && !state.exactAllowed) ...[
            const SizedBox(height: CsSpace.md),
            CsSection(
              children: [
                CsRow(
                  icon: Icons.alarm_on_outlined,
                  title: l10n.exactAlarmTitle,
                  subtitle: l10n.exactAlarmHint,
                  showChevron: false,
                  trailing: TextButton(
                    onPressed: cubit.requestExact,
                    child: Text(l10n.allow),
                  ),
                  onTap: cubit.requestExact,
                ),
              ],
            ),
          ],
          const SizedBox(height: CsSpace.lg),
          AnimatedOpacity(
            duration: CsMotion.fast,
            opacity: state.active ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !state.active,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Title(l10n.remindBefore),
                  Wrap(
                    spacing: CsSpace.sm,
                    runSpacing: CsSpace.sm,
                    children: [
                      for (final m in ReminderSettings.minuteChoices)
                        ChoiceChip(
                          label: Text(l10n.remindersOnValue(m)),
                          selected: s.minutesBefore == m,
                          showCheckmark: false,
                          onSelected: (_) => cubit.setMinutes(m),
                        ),
                    ],
                  ),
                  const SizedBox(height: CsSpace.lg),
                  if (courses.isEmpty)
                    Text(l10n.noCoursesYet, style: context.text.bodyMedium)
                  else ...[
                    CsSection(
                      title: l10n.courses,
                      children: [
                        for (final c
                            in courses.values.toList()..sort(
                              (a, b) => a.courseCode.compareTo(b.courseCode),
                            ))
                          CsRow(
                            icon: Icons.menu_book_outlined,
                            title: c.courseCode,
                            subtitle: c.courseTitle.isEmpty
                                ? null
                                : c.courseTitle,
                            showChevron: false,
                            trailing: Switch(
                              value: !s.isMuted(c.courseCode),
                              onChanged: (on) =>
                                  cubit.setCourseOn(c.courseCode, on),
                            ),
                            onTap: () => cubit.setCourseOn(
                              c.courseCode,
                              s.isMuted(c.courseCode),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: CsSpace.sm),
                    Text(l10n.coursesHint, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(CsSpace.xs, 0, CsSpace.xs, CsSpace.sm),
    child: Text(
      text.toUpperCase(),
      style: context.text.labelMedium?.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
