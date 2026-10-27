import 'dart:io';

import 'package:campus_ui/campus_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bangla falls back to the bundled Noto Sans Bengali everywhere', () {
    for (final theme in [CsTheme.light, CsTheme.dark]) {
      expect(
        theme.textTheme.bodyLarge?.fontFamilyFallback,
        contains(CsTypography.banglaFamily),
      );
      expect(
        theme.textTheme.labelLarge?.fontFamilyFallback,
        contains(CsTypography.banglaFamily),
      );
    }
  });

  test('every declared weight file exists, with its license', () {
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      expect(
        File('fonts/NotoSansBengali/NotoSansBengali-$w.ttf').existsSync(),
        isTrue,
        reason: w,
      );
    }
    expect(File('fonts/NotoSansBengali/OFL.txt').existsSync(), isTrue);
  });
}
