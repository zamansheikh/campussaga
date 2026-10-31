import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/cs_icons.dart';
import '../tokens/dimensions.dart';

/// One choice in [CsOptionSheet].
class CsOption<T> {
  const CsOption(this.value, this.label, {this.subtitle, this.icon});

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Bottom sheet with a single-choice list; returns the picked value.
abstract final class CsOptionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<CsOption<T>> options,
    required T selected,
    String? message,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      // Cover the bottom navigation bar too.
      useRootNavigator: true,
      // As tall as the options need, scrolling past most of the screen.
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              0,
              CsSpace.md,
              CsSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CsSpace.xs,
                    0,
                    CsSpace.xs,
                    CsSpace.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleMedium),
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: CsSpace.xxs),
                          child: Text(
                            message,
                            style: context.text.bodySmall?.copyWith(
                              color: context.cs.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final o in options)
                  Padding(
                    padding: const EdgeInsets.only(top: CsSpace.sm),
                    child: _OptionTile(
                      option: o,
                      selected: o.value == selected,
                      onTap: () => Navigator.of(context).pop(o.value),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CsOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: selected ? cs.primaryContainer : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.md),
        side: BorderSide(color: selected ? cs.primary : cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  color: selected ? cs.onPrimaryContainer : cs.textSecondary,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onPrimaryContainer : null,
                      ),
                    ),
                    if (option.subtitle != null)
                      Text(option.subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected ? CsIcons.checkCircle : CsIcons.circle,
                color: selected ? cs.primary : cs.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
