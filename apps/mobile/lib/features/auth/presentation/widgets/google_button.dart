import 'package:flutter/material.dart';

/// "Continue with Google" in Google's branding: white (light) or near-black
/// (dark) fill, grey outline and the four-colour G.
/// https://developers.google.com/identity/branding-guidelines
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF131314) : Colors.white;
    final stroke = dark ? const Color(0xFF8E918F) : const Color(0xFF747775);
    final text = dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: text,
        disabledBackgroundColor: fill,
        disabledForegroundColor: text.withValues(alpha: 0.5),
        side: BorderSide(color: stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 20,
            child: busy
                ? CircularProgressIndicator(strokeWidth: 2, color: text)
                : const CustomPaint(painter: _GoogleG()),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Google's G, from the official 48 x 48 SVG.
class _GoogleG extends CustomPainter {
  const _GoogleG();

  static const _parts = [
    (
      Color(0xFFEA4335),
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
          '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 '
          '9.5z',
    ),
    (
      Color(0xFF4285F4),
      'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
          '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
    ),
    (
      Color(0xFFFBBC05),
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
          'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
    ),
    (
      Color(0xFF34A853),
      'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
          '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 '
          '48z',
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, data) in _parts) {
      canvas.drawPath(parseSvgPath(data), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_GoogleG oldDelegate) => false;
}

/// Minimal SVG path parser: M L H V C S Z, absolute and relative. Enough
/// for the G above; not a general SVG renderer.
@visibleForTesting
Path parseSvgPath(String d) {
  final tokens = RegExp(
    r'[MmLlHhVvCcSsZz]|-?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = '';
  double x = 0, y = 0, startX = 0, startY = 0;
  double? lastCx, lastCy;
  double n() => double.parse(tokens[i++]);
  bool isNumber() =>
      i < tokens.length && !RegExp('[A-Za-z]').hasMatch(tokens[i]);

  while (i < tokens.length) {
    if (!isNumber()) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + n();
        y = oy + n();
        startX = x;
        startY = y;
        path.moveTo(x, y);
        cmd = rel ? 'l' : 'L'; // extra pairs after M are line-tos
        lastCx = null;
      case 'L':
        x = ox + n();
        y = oy + n();
        path.lineTo(x, y);
        lastCx = null;
      case 'H':
        x = ox + n();
        path.lineTo(x, y);
        lastCx = null;
      case 'V':
        y = oy + n();
        path.lineTo(x, y);
        lastCx = null;
      case 'C':
        final x1 = ox + n(), y1 = oy + n();
        final x2 = ox + n(), y2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCx = x2;
        lastCy = y2;
      case 'S':
        final x1 = lastCx == null ? x : 2 * x - lastCx;
        final y1 = lastCy == null || lastCx == null ? y : 2 * y - lastCy;
        final x2 = ox + n(), y2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCx = x2;
        lastCy = y2;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastCx = null;
    }
  }
  return path;
}
