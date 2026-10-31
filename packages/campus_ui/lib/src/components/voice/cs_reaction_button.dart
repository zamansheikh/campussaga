import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/cs_tokens.dart';
import '../../tokens/dimensions.dart';
import 'cs_post.dart';

/// The React button of a post, like Facebook's: a tap gives the first
/// reaction (or takes yours back); press and hold opens the reactions
/// above it, and without lifting the finger slide across them: the one
/// under the finger grows and shows its name, and lifting picks it. Lift
/// anywhere else and the reactions stay open to tap, or tap outside to
/// close them.
class CsReactionButton extends StatefulWidget {
  const CsReactionButton({
    super.key,
    required this.label,
    required this.idleIcon,
    required this.options,
    this.emoji,
    this.activeColor,
    this.selected,
    this.onTap,
    this.onPicked,
    this.semanticLabel,
  });

  /// "Like", or the name of the caller's reaction.
  final String label;

  /// Shown before any reaction (an outline heart).
  final IconData idleIcon;

  /// The reactions: emoji and its name.
  final List<(String emoji, String label)> options;

  /// The caller's reaction, if any.
  final String? emoji;
  final Color? activeColor;

  /// Index of the caller's reaction in [options].
  final int? selected;

  /// Null: the button is off (offline).
  final VoidCallback? onTap;
  final ValueChanged<int>? onPicked;
  final String? semanticLabel;

  @override
  State<CsReactionButton> createState() => _CsReactionButtonState();
}

class _CsReactionButtonState extends State<CsReactionButton> {
  OverlayEntry? _entry;
  final _hovered = ValueNotifier<int?>(null);
  final _tray = GlobalKey<_TrayState>();
  _TrayGeometry? _geometry;

  bool get _enabled => widget.onTap != null && widget.onPicked != null;

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _hovered.dispose();
    super.dispose();
  }

  void _open() {
    if (_entry != null || !_enabled) return;
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) return;
    final anchor =
        box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final geometry = _TrayGeometry.place(
      anchor: anchor,
      count: widget.options.length,
      screen: overlayBox.size,
      topInset: MediaQuery.paddingOf(context).top,
    );
    _geometry = geometry;
    _hovered.value = null;
    HapticFeedback.mediumImpact();
    _entry = OverlayEntry(
      builder: (_) => _Tray(
        key: _tray,
        geometry: geometry,
        options: widget.options,
        selected: widget.selected,
        hovered: _hovered,
        onPick: _pick,
        onDismiss: _close,
      ),
    );
    overlay.insert(_entry!);
  }

  /// The finger moved (still holding): which reaction is under it.
  void _track(Offset global) {
    final g = _geometry;
    if (g == null) return;
    final overlayBox =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    final local = overlayBox?.globalToLocal(global) ?? global;
    final i = g.hit(local);
    if (i != _hovered.value) {
      if (i != null) HapticFeedback.selectionClick();
      _hovered.value = i;
    }
  }

  void _release() {
    final i = _hovered.value;
    if (i != null) {
      _pick(i);
    }
    // Lifted elsewhere: the reactions stay open to tap.
  }

  void _pick(int i) {
    widget.onPicked?.call(i);
    _close();
  }

  Future<void> _close() async {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _geometry = null;
    await _tray.currentState?.hide();
    entry.remove();
    _hovered.value = null;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: _enabled ? (_) => _open() : null,
    onLongPressMoveUpdate: _enabled ? (d) => _track(d.globalPosition) : null,
    onLongPressEnd: _enabled ? (_) => _release() : null,
    child: CsActionButton(
      icon: widget.idleIcon,
      emoji: widget.emoji,
      label: widget.label,
      active: widget.emoji != null,
      activeColor: widget.activeColor,
      semanticLabel: widget.semanticLabel,
      onTap: widget.onTap,
    ),
  );
}

/// Where the tray sits and where each reaction is, in overlay coordinates.
class _TrayGeometry {
  const _TrayGeometry(this.rect, this.count);

  factory _TrayGeometry.place({
    required Rect anchor,
    required int count,
    required Size screen,
    required double topInset,
  }) {
    final width = item * count + pad * 2;
    final left = (anchor.left - pad).clamp(
      CsSpace.sm,
      screen.width - width - CsSpace.sm,
    );
    final above = anchor.top - height - CsSpace.sm;
    // Room for the grown emoji and its name above the tray.
    final top = above > topInset + 100 ? above : anchor.bottom + CsSpace.sm;
    return _TrayGeometry(Rect.fromLTWH(left, top, width, height), count);
  }

  static const item = 48.0;
  static const pad = 6.0;
  static const height = 56.0;

  final Rect rect;
  final int count;

  /// The reaction at [p], with room around the tray as on Facebook (the
  /// finger may be a little above or below it).
  int? hit(Offset p) {
    final area = Rect.fromLTRB(
      rect.left,
      rect.top - 72,
      rect.right,
      rect.bottom + 56,
    );
    if (!area.contains(p)) return null;
    final i = ((p.dx - rect.left - pad) / item).floor();
    return i < 0 || i >= count ? null : i;
  }
}

class _Tray extends StatefulWidget {
  const _Tray({
    super.key,
    required this.geometry,
    required this.options,
    required this.selected,
    required this.hovered,
    required this.onPick,
    required this.onDismiss,
  });

  final _TrayGeometry geometry;
  final List<(String, String)> options;
  final int? selected;
  final ValueNotifier<int?> hovered;
  final ValueChanged<int> onPick;
  final VoidCallback onDismiss;

  @override
  State<_Tray> createState() => _TrayState();
}

class _TrayState extends State<_Tray> with SingleTickerProviderStateMixin {
  late final _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 140),
  )..forward();

  Future<void> hide() => _show.reverse();

  @override
  void dispose() {
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final g = widget.geometry;
    final grow = CurvedAnimation(parent: _show, curve: Curves.easeOutBack);
    return Stack(
      children: [
        // Tap outside: close.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: FadeTransition(
              opacity: _show,
              child: const ColoredBox(color: Color(0x14000000)),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: g.rect,
          child: FadeTransition(
            opacity: _show,
            child: ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.0).animate(grow),
              alignment: Alignment.bottomLeft,
              child: Material(
                color: cs.surface,
                elevation: 10,
                shadowColor: Colors.black45,
                shape: StadiumBorder(side: BorderSide(color: cs.border)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _TrayGeometry.pad,
                  ),
                  child: ValueListenableBuilder<int?>(
                    valueListenable: widget.hovered,
                    builder: (context, hovered, _) => Row(
                      children: [
                        for (var i = 0; i < widget.options.length; i++)
                          _Face(
                            emoji: widget.options[i].$1,
                            label: widget.options[i].$2,
                            index: i,
                            show: _show,
                            hovered: hovered == i,
                            shrunk: hovered != null && hovered != i,
                            selected: widget.selected == i,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onPick(i);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One reaction in the tray: pops in after the one before it; grows and
/// lifts with its name above while the finger is on it.
class _Face extends StatelessWidget {
  const _Face({
    required this.emoji,
    required this.label,
    required this.index,
    required this.show,
    required this.hovered,
    required this.shrunk,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final int index;
  final Animation<double> show;
  final bool hovered;
  final bool shrunk;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final start = (index * 0.08).clamp(0.0, 0.6);
    final pop = CurvedAnimation(
      parent: show,
      curve: Interval(
        start,
        (start + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    );
    final scale = hovered ? 1.6 : (shrunk ? 0.88 : 1.0);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _TrayGeometry.item,
          height: _TrayGeometry.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (selected && !hovered)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ScaleTransition(
                scale: pop,
                child: AnimatedSlide(
                  offset: hovered ? const Offset(0, -0.45) : Offset.zero,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: scale,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30, height: 1.15),
                    ),
                  ),
                ),
              ),
              // The name, clear above the grown emoji.
              Positioned(
                top: -74,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CsSpace.sm,
                        vertical: 3,
                      ),
                      // A dark pill with white text reads on light and dark.
                      decoration: BoxDecoration(
                        color: const Color(0xF2111827),
                        borderRadius: BorderRadius.circular(CsRadius.full),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: context.text.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
