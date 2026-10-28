import 'package:flutter/material.dart';

import '../../tokens/dimensions.dart';

/// 1–4 photos: one wide, or a 2-column grid. [builder] draws photo i.
class CsImageGrid extends StatelessWidget {
  const CsImageGrid({
    super.key,
    required this.count,
    required this.builder,
    this.onTap,
    this.semanticLabel,
  });

  final int count;
  final Widget Function(BuildContext context, int index) builder;
  final void Function(int index)? onTap;

  /// "Photo {n}" label maker for screen readers.
  final String Function(int index)? semanticLabel;

  Widget _tile(BuildContext context, int i, double aspect) => Semantics(
    button: onTap != null,
    image: true,
    label: semanticLabel?.call(i),
    child: GestureDetector(
      onTap: onTap == null ? null : () => onTap!(i),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CsRadius.md),
        child: AspectRatio(aspectRatio: aspect, child: builder(context, i)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    if (count == 1) return _tile(context, 0, 16 / 10);
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: CsSpace.sm,
      crossAxisSpacing: CsSpace.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (var i = 0; i < count; i++) _tile(context, i, 1)],
    );
  }
}
