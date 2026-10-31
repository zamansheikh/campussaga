import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/dimensions.dart';

/// The main action in a top bar ("Post", "Save"): a compact pill that fits
/// the bar, instead of the full-height primary button. Disabled, it turns
/// grey (clearly not ready); [busy] shows a small spinner in its place.
/// The touch target stays 48 px.
class CsBarButton extends StatelessWidget {
  const CsBarButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// Height of the pill (the bar is 56).
  static const height = 36.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(right: CsSpace.sm),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, height),
          padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
          shape: const StadiumBorder(),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          textStyle: context.text.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          disabledBackgroundColor: cs.surfaceVariant,
          disabledForegroundColor: cs.textSecondary,
        ),
        child: busy
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.textSecondary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
