import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

/// Weekly routine. R1: day strip + classes per day, with changes marked.
class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navRoutine)),
      body: CsEmptyState(
        icon: Icons.calendar_view_week_outlined,
        title: l10n.routineEmptyTitle,
        message: l10n.routineEmptyMessage,
      ),
    );
  }
}
