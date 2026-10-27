import 'package:flutter/material.dart';

import '../tokens/dimensions.dart';

/// Scrollable page body: screen padding and a readable max width on
/// tablets and landscape.
class CsPage extends StatelessWidget {
  const CsPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(
      CsSpace.screen,
      CsSpace.sm,
      CsSpace.screen,
      CsSpace.xl,
    ),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: CsSize.contentMaxWidth),
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );
  }
}
