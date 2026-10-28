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
      (Icons.badge_outlined, l10n.voiceAnon1),
      (Icons.lock_outline, l10n.voiceAnon2),
      (Icons.masks_outlined, l10n.voiceAnon3),
      (Icons.photo_outlined, l10n.voiceAnon4),
      (Icons.schedule, l10n.voiceAnon5),
      (Icons.gavel_outlined, l10n.voiceAnon6),
      (Icons.warning_amber_outlined, l10n.voiceAnon7),
      (Icons.health_and_safety_outlined, l10n.voiceAnon8),
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
                Icon(Icons.masks, size: 36, color: cs.onPrimaryContainer),
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
