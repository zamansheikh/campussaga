import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/dimensions.dart';

/// Page indicator: the current page is a wider pill.
class CsDots extends StatelessWidget {
  const CsDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: CsMotion.normal,
            curve: CsMotion.curve,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? cs.primary : cs.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
