import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

/// Home screen. R1: next class with countdown, then the rest of today.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navToday)),
      body: CsEmptyState(
        icon: Icons.school_outlined,
        title: l10n.todayEmptyTitle,
        message: l10n.todayEmptyMessage,
        actionLabel: l10n.joinClassGroup,
        onAction: () =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
      ),
    );
  }
}
