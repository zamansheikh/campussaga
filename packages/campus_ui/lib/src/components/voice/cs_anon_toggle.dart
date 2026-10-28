import 'package:flutter/material.dart';

import '../../theme/cs_tokens.dart';
import '../../tokens/dimensions.dart';

/// "Post anonymously": the mask icon, a one-line explanation and an
/// optional link to how anonymity works.
class CsAnonToggle extends StatelessWidget {
  const CsAnonToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    this.linkLabel,
    this.onLink,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String subtitle;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      decoration: BoxDecoration(
        color: value ? cs.primaryContainer : cs.surfaceVariant,
        borderRadius: BorderRadius.circular(CsRadius.md),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Icon(
            value ? Icons.masks : Icons.person_outline,
            color: value ? cs.onPrimaryContainer : cs.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(subtitle, style: context.text.bodySmall),
                if (linkLabel != null && onLink != null)
                  InkWell(
                    onTap: onLink,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        linkLabel!,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
