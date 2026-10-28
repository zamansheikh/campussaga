import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

/// "How anonymity works": what we promise, and what students should know.
class AnonymityPage extends StatelessWidget {
  const AnonymityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final points = [
      (CsIcons.idCard, l10n.voiceAnon1),
      (CsIcons.lock, l10n.voiceAnon2),
      (CsIcons.anonymous, l10n.voiceAnon3),
      (CsIcons.image, l10n.voiceAnon4),
      (CsIcons.time, l10n.voiceAnon5),
      (CsIcons.rules, l10n.voiceAnon6),
      (CsIcons.warning, l10n.voiceAnon7),
      (CsIcons.safety, l10n.voiceAnon8),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.voiceAnonTitle)),
      body: CsPage(
        children: [
          Container(
            padding: const EdgeInsets.all(CsSpace.md),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(CsRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  CsIcons.anonymousFill,
                  size: 36,
                  color: cs.onPrimaryContainer,
                ),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: Text(
                    l10n.voiceAnonIntro,
                    style: context.text.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          for (final (icon, text) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: CsSpace.md),
                  Expanded(child: Text(text, style: context.text.bodyLarge)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
