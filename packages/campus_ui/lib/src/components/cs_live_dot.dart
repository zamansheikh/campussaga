import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';

/// The red "live" dot. It sends out one ripple when it appears and again
/// each time [pulse] changes (fresh data), so it never animates forever.
class CsLiveDot extends StatefulWidget {
  const CsLiveDot({super.key, this.size = 8, this.pulse, this.color});

  final double size;

  /// Change it (e.g. to the time of the latest update) to ripple again.
  final Object? pulse;

  /// Defaults to the theme's error red.
  final Color? color;

  @override
  State<CsLiveDot> createState() => _CsLiveDotState();
}

class _CsLiveDotState extends State<CsLiveDot>
    with SingleTickerProviderStateMixin {
  late final _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _ripple.forward();
  }

  @override
  void didUpdateWidget(CsLiveDot old) {
    super.didUpdateWidget(old);
    if (old.pulse != widget.pulse) _ripple.forward(from: 0);
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.cs.error;
    final box = widget.size * 2.6;
    return SizedBox.square(
      dimension: box,
      child: AnimatedBuilder(
        animation: _ripple,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_ripple.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              if (_ripple.isAnimating)
                Container(
                  width: widget.size + (box - widget.size) * t,
                  height: widget.size + (box - widget.size) * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.35 * (1 - t)),
                  ),
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "● LIVE" with an optional detail after it ("● LIVE · 3 sharing").
class CsLiveLabel extends StatelessWidget {
  const CsLiveLabel({super.key, required this.label, this.detail, this.pulse});

  final String label;
  final String? detail;
  final Object? pulse;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsLiveDot(pulse: pulse),
        const SizedBox(width: 2),
        Text(
          label.toUpperCase(),
          style: context.text.labelMedium?.copyWith(
            color: cs.error,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        if (detail != null)
          Flexible(
            child: Text(
              ' · $detail',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                color: cs.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
