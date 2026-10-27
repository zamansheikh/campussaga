import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';

/// Design tokens that Material's [ThemeData] has no slot for
/// (status colors, accent, ...). Read them with `context.cs`.
@immutable
class CsTokens extends ThemeExtension<CsTokens> {
  const CsTokens({required this.colors});

  final CsColors colors;

  @override
  CsTokens copyWith({CsColors? colors}) =>
      CsTokens(colors: colors ?? this.colors);

  @override
  CsTokens lerp(covariant CsTokens? other, double t) {
    if (other == null) return this;
    return CsTokens(colors: CsColors.lerp(colors, other.colors, t));
  }
}

extension CsContext on BuildContext {
  /// Semantic colors of the current theme.
  CsColors get cs => Theme.of(this).extension<CsTokens>()!.colors;

  TextTheme get text => Theme.of(this).textTheme;
}
