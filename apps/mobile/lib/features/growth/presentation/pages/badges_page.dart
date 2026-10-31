import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../widgets/badges_section.dart';

/// Every badge: the ones I earned, and how to earn the rest.
class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).badgesPageTitle)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        CsSpace.screen,
        CsSpace.sm,
        CsSpace.screen,
        CsSpace.xl,
      ),
      children: const [BadgesSection()],
    ),
  );
}
