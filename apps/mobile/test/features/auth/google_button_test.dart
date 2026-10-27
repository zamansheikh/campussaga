import 'package:campussaga/features/auth/presentation/widgets/google_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the G paths into closed shapes inside the 48 box', () {
    final path = parseSvgPath(
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0z',
    );
    final b = path.getBounds();
    expect(b.left, greaterThanOrEqualTo(23.9));
    expect(b.top, closeTo(0, 0.01));
    expect(b.right, closeTo(40.06, 0.01));
    expect(b.bottom, closeTo(13.1, 0.01));
  });

  test('S reflects the previous control point', () {
    final path = parseSvgPath('M0 0C0 10 10 10 10 0s10-10 10 0z');
    expect(path.getBounds().right, closeTo(20, 0.01));
    expect(path.getBounds().top, lessThan(0));
  });
}
