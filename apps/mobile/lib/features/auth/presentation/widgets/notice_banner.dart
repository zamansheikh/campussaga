import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

/// Inline error message with an icon, read out by screen readers.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(CsRadius.md),
          border: Border.all(color: cs.error.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.text.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
