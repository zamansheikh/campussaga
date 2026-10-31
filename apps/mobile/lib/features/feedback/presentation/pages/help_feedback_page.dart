import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';

/// Profile → Help & feedback: send feedback, or read the answers.
class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpFeedback)),
      body: CsPage(
        children: [
          CsSection(
            children: [
              CsRow(
                icon: CsIcons.send,
                title: l10n.feedbackSend,
                subtitle: l10n.helpFeedbackHint,
                onTap: () => context.push(Routes.feedbackSend),
              ),
              CsRow(
                icon: CsIcons.comment,
                title: l10n.feedbackMine,
                onTap: () => context.push(Routes.feedbackMine),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
