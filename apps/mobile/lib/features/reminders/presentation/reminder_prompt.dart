import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/reminders_cubit.dart';

/// Asks once, on Today, whether to turn on class reminders.
class ReminderPrompt extends StatelessWidget {
  const ReminderPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final cubit = context.read<RemindersCubit>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CsSpace.md + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.statusInProgress.bg,
                    borderRadius: BorderRadius.circular(CsRadius.md),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: cs.statusInProgress.fg,
                  ),
                ),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reminderPromptTitle,
                        style: context.text.titleMedium,
                      ),
                      Text(
                        l10n.reminderPromptBody,
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: cubit.enable,
                    child: Text(l10n.turnOn),
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: TextButton(
                    onPressed: cubit.dismissPrompt,
                    child: Text(l10n.notNow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
