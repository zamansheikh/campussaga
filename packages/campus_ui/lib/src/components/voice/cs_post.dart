import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/cs_tokens.dart';
import '../../tokens/dimensions.dart';

/// An anonymous person as a friendly face: an animal on a soft colour,
/// picked from [seed] (a post id or a per-post handle), so the same
/// anonymous author looks the same everywhere on that post and different on
/// every other post. It says nothing about who they are.
class CsAnonAvatar extends StatelessWidget {
  const CsAnonAvatar({super.key, required this.seed, this.size = 40});

  final String seed;
  final double size;

  static const faces = [
    '🦊', '🐼', '🐨', '🐯', '🦁', '🐸', '🐵', '🐧', '🦉', '🐙', //
    '🦄', '🐝', '🐢', '🐬', '🐳', '🦋', '🐰', '🐻', '🐮', '🐷', //
    '🐶', '🐱', '🐹', '🦝', '🦔', '🐺', '🦒', '🦓', '🐘', '🦜', //
  ];

  // Soft tones that sit well on light and dark cards.
  static const _colors = [
    Color(0xFFFFD8B8),
    Color(0xFFC9E7F5),
    Color(0xFFD3F0C8),
    Color(0xFFFFCFE1),
    Color(0xFFE2D6F8),
    Color(0xFFFFF0B3),
    Color(0xFFC6EFE6),
    Color(0xFFF8D5CB),
  ];

  static int _hash(String s) =>
      s.codeUnits.fold(17, (a, b) => (a * 31 + b) & 0x3fffffff);

  @override
  Widget build(BuildContext context) {
    final h = _hash(seed);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colors[h % _colors.length],
        shape: BoxShape.circle,
      ),
      child: Text(
        faces[(h ~/ _colors.length) % faces.length],
        style: TextStyle(fontSize: size * 0.56, height: 1.1),
      ),
    );
  }
}

/// Who posted, when and where: avatar, name (with badges), a muted line,
/// and something on the right (a status chip, a menu).
class CsPostHeader extends StatelessWidget {
  const CsPostHeader({
    super.key,
    required this.avatar,
    required this.name,
    this.nameIcon,
    this.badges = const [],
    this.subtitle = '',
    this.subtitleIcon,
    this.trailing,
  });

  final Widget avatar;
  final String name;

  /// Small icon after the name (the mask for anonymous posts).
  final IconData? nameIcon;
  final List<Widget> badges;
  final String subtitle;
  final IconData? subtitleIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final muted = context.text.bodySmall?.copyWith(color: cs.textSecondary);
    return Row(
      children: [
        avatar,
        const SizedBox(width: CsSpace.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (nameIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(nameIcon, size: 15, color: cs.textSecondary),
                  ],
                  for (final b in badges) ...[const SizedBox(width: 6), b],
                ],
              ),
              if (subtitle.isNotEmpty)
                Row(
                  children: [
                    if (subtitleIcon != null) ...[
                      Icon(subtitleIcon, size: 13, color: cs.textSecondary),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: CsSpace.xs), trailing!],
      ],
    );
  }
}

/// Text cut at [maxLines] with a "See more" line when there is more (cut by
/// the server, or longer than fits).
class CsClampedText extends StatelessWidget {
  const CsClampedText({
    super.key,
    required this.text,
    required this.moreLabel,
    this.maxLines = 6,
    this.cut = false,
    this.style,
  });

  final String text;
  final String moreLabel;
  final int maxLines;

  /// The server sent only the start of a longer text.
  final bool cut;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? context.text.bodyLarge;
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: box.maxWidth);
        final more = cut || painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
            if (more)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  moreLabel,
                  style: context.text.labelLarge?.copyWith(
                    color: context.cs.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 1–4 photos laid out like a social post: one at its own shape (within
/// limits), two side by side, three as one large and two small, four as a
/// grid. [aspect] is the first photo's width / height, when known.
class CsMediaGrid extends StatelessWidget {
  const CsMediaGrid({
    super.key,
    required this.count,
    required this.builder,
    this.aspect,
    this.onTap,
    this.semanticLabel,
    this.radius = 0,
  });

  final int count;
  final Widget Function(BuildContext context, int index) builder;
  final double? aspect;
  final void Function(int index)? onTap;
  final String Function(int index)? semanticLabel;
  final double radius;

  static const _gap = 3.0;

  Widget _tile(BuildContext context, int i) => Semantics(
    button: onTap != null,
    image: true,
    label: semanticLabel?.call(i),
    child: GestureDetector(
      onTap: onTap == null ? null : () => onTap!(i),
      child: SizedBox.expand(child: builder(context, i)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final Widget grid = switch (count) {
      1 => AspectRatio(
        aspectRatio: (aspect ?? 4 / 3).clamp(0.8, 1.91),
        child: _tile(context, 0),
      ),
      2 => AspectRatio(
        aspectRatio: 2,
        child: Row(
          children: [
            Expanded(child: _tile(context, 0)),
            const SizedBox(width: _gap),
            Expanded(child: _tile(context, 1)),
          ],
        ),
      ),
      3 => AspectRatio(
        aspectRatio: 1.5,
        child: Row(
          children: [
            Expanded(flex: 2, child: _tile(context, 0)),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _tile(context, 1)),
                  const SizedBox(height: _gap),
                  Expanded(child: _tile(context, 2)),
                ],
              ),
            ),
          ],
        ),
      ),
      _ => AspectRatio(
        aspectRatio: 1.25,
        child: Column(
          children: [
            for (final row in const [0, 2]) ...[
              if (row > 0) const SizedBox(height: _gap),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _tile(context, row)),
                    const SizedBox(width: _gap),
                    Expanded(child: _tile(context, row + 1)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    };
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: grid);
  }
}

/// One button of a post's action bar: an icon (or an emoji) and a label,
/// coloured when [active]. Long-press is used for the reaction picker.
class CsActionButton extends StatelessWidget {
  const CsActionButton({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.active = false,
    this.activeColor,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;

  /// Shown instead of [icon] (the caller's reaction).
  final String? emoji;
  final bool active;
  final Color? activeColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = active ? (activeColor ?? cs.primary) : cs.textSecondary;
    return Semantics(
      button: true,
      toggled: active,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(CsRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 18, height: 1.1))
              else if (icon != null)
                Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
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

/// The row of equal buttons under every post (react · comment · share).
class CsActionBar extends StatelessWidget {
  const CsActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: CsSpace.xs),
    child: Row(children: [for (final c in children) Expanded(child: c)]),
  );
}

/// "❤️😂 23 · 5 comments": the top reactions as overlapping emojis with the
/// total, and the comment count on the right.
class CsReactionSummary extends StatelessWidget {
  const CsReactionSummary({
    super.key,
    required this.emojis,
    required this.countLabel,
    this.trailing = '',
    this.onTrailingTap,
  });

  final List<String> emojis;
  final String countLabel;
  final String trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final muted = context.text.bodySmall?.copyWith(color: cs.textSecondary);
    return Row(
      children: [
        if (emojis.isNotEmpty) ...[
          SizedBox(
            width: 14.0 * emojis.length + 8,
            height: 22,
            child: Stack(
              children: [
                for (var i = emojis.length - 1; i >= 0; i--)
                  Positioned(
                    left: 14.0 * i,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 1.5),
                      ),
                      child: Text(
                        emojis[i],
                        style: const TextStyle(fontSize: 12, height: 1.1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(countLabel, style: muted),
        ],
        const Spacer(),
        if (trailing.isNotEmpty)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailing, style: muted),
          ),
      ],
    );
  }
}

/// The reaction picker: a pill of emojis over the button that was held.
/// Answers the index picked, or null.
abstract final class CsReactionPicker {
  static Future<int?> show(
    BuildContext context, {
    required List<(String emoji, String label)> options,
    required Rect anchor,
    int? selected,
  }) {
    HapticFeedback.mediumImpact();
    return Navigator.of(context, rootNavigator: true).push<int>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black12,
        barrierLabel: MaterialLocalizations.of(context)
            .modalBarrierDismissLabel,
        transitionDuration: CsMotion.fast,
        reverseTransitionDuration: CsMotion.fast,
        pageBuilder: (context, _, _) =>
            _Picker(options: options, anchor: anchor, selected: selected),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.options,
    required this.anchor,
    required this.selected,
  });

  final List<(String, String)> options;
  final Rect anchor;
  final int? selected;

  static const _item = 48.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final screen = MediaQuery.sizeOf(context);
    final width = _item * options.length + CsSpace.sm * 2;
    final left = (anchor.left - CsSpace.xs).clamp(
      CsSpace.sm,
      screen.width - width - CsSpace.sm,
    );
    final above = anchor.top - _item - CsSpace.md * 2;
    final top = above > MediaQuery.paddingOf(context).top
        ? above
        : anchor.bottom + CsSpace.sm;
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: cs.surface,
            elevation: 8,
            shadowColor: Colors.black38,
            shape: StadiumBorder(side: BorderSide(color: cs.border)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CsSpace.sm,
                vertical: CsSpace.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < options.length; i++)
                    _PickerItem(
                      emoji: options[i].$1,
                      label: options[i].$2,
                      delay: i,
                      selected: selected == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop(i);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerItem extends StatelessWidget {
  const _PickerItem({
    required this.emoji,
    required this.label,
    required this.delay,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final int delay;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 180 + delay * 40),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Transform.scale(scale: t, child: child),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(
                    color: context.cs.primaryContainer,
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 30, height: 1.1),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One answer of a poll, as the screen shows it.
class CsPollChoice {
  const CsPollChoice({required this.label, this.share, this.mine = false});

  final String label;

  /// 0–1 of the votes, when results are shown.
  final double? share;
  final bool mine;
}

/// A poll: buttons to vote, or bars with the results once they show.
class CsPollView extends StatelessWidget {
  const CsPollView({
    super.key,
    required this.choices,
    required this.footer,
    this.onVote,
    this.percentLabel,
  });

  final List<CsPollChoice> choices;

  /// "63 votes · 2 days left".
  final String footer;

  /// Null: can't vote (closed, voted, offline).
  final void Function(int index)? onVote;

  /// Formats a share as "42%" in the app's language.
  final String Function(double share)? percentLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final results = choices.any((c) => c.share != null);
    final best = results
        ? choices.map((c) => c.share ?? 0).reduce((a, b) => a > b ? a : b)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < choices.length; i++) ...[
          if (i > 0) const SizedBox(height: CsSpace.sm),
          if (results)
            _ResultBar(
              choice: choices[i],
              leading: (choices[i].share ?? 0) == best && best > 0,
              percent:
                  percentLabel?.call(choices[i].share ?? 0) ??
                  '${((choices[i].share ?? 0) * 100).round()}%',
            )
          else
            Semantics(
              button: true,
              child: Material(
                color: Colors.transparent,
                shape: StadiumBorder(side: BorderSide(color: cs.primary)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onVote == null ? null : () => onVote!(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CsSpace.md,
                      vertical: CsSpace.sm,
                    ),
                    child: Text(
                      choices[i].label,
                      textAlign: TextAlign.center,
                      style: context.text.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: CsSpace.sm),
        Text(
          footer,
          style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
        ),
      ],
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.choice,
    required this.leading,
    required this.percent,
  });

  final CsPollChoice choice;
  final bool leading;
  final String percent;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final style = context.text.labelLarge?.copyWith(
      fontWeight: leading || choice.mine ? FontWeight.w800 : FontWeight.w600,
      color: cs.textPrimary,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(CsRadius.sm),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: cs.surfaceVariant)),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: choice.share ?? 0),
              duration: CsMotion.normal * 2,
              curve: CsMotion.curve,
              builder: (_, t, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: t.clamp(0, 1),
                child: ColoredBox(
                  color: cs.primary.withValues(alpha: leading ? 0.38 : 0.2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CsSpace.sm + 4,
              vertical: CsSpace.sm + 2,
            ),
            child: Row(
              children: [
                Expanded(child: Text(choice.label, style: style)),
                if (choice.mine) ...[
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                ],
                Text(percent, style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A post in a list or opened: header, (issue title), text, photos, an
/// extra block (poll, issue status), badges, the reaction summary and the
/// action bar. Photos run edge to edge.
class CsPostCard extends StatelessWidget {
  const CsPostCard({
    super.key,
    required this.header,
    required this.text,
    required this.actions,
    this.title,
    this.textCut = false,
    this.moreLabel = '',
    this.maxLines = 6,
    this.bigText = false,
    this.media,
    this.extra,
    this.tags = const [],
    this.summary,
    this.onTap,
    this.framed = true,
  });

  final Widget header;
  final String? title;
  final String text;
  final bool textCut;
  final String moreLabel;

  /// Null: the whole text (an opened post, selectable).
  final int? maxLines;

  /// A short post with no photos is shown in large type.
  final bool bigText;
  final Widget? media;
  final Widget? extra;
  final List<Widget> tags;
  final Widget? summary;
  final Widget actions;
  final VoidCallback? onTap;

  /// A card with a border (lists), or flat (an opened post).
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final textStyle = bigText
        ? context.text.titleLarge?.copyWith(fontWeight: FontWeight.w500)
        : context.text.bodyLarge;
    const side = EdgeInsets.symmetric(horizontal: CsSpace.md);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.md,
            CsSpace.md,
            CsSpace.sm,
            0,
          ),
          child: header,
        ),
        if (title != null && title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm + 2,
              CsSpace.md,
              0,
            ),
            child: Text(
              title!,
              style: framed
                  ? context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )
                  : context.text.headlineSmall,
            ),
          ),
        if (text.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              CsSpace.md,
              title != null && title!.isNotEmpty ? 4 : CsSpace.sm + 2,
              CsSpace.md,
              0,
            ),
            child: maxLines == null
                ? SelectableText(text, style: textStyle)
                : CsClampedText(
                    text: text,
                    cut: textCut,
                    moreLabel: moreLabel,
                    maxLines: maxLines!,
                    style: title != null && title!.isNotEmpty
                        ? context.text.bodyMedium?.copyWith(
                            color: cs.textSecondary,
                          )
                        : textStyle,
                  ),
          ),
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm,
              CsSpace.md,
              0,
            ),
            child: Wrap(spacing: 6, runSpacing: 6, children: tags),
          ),
        if (media != null)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.sm + 4),
            child: media,
          ),
        if (extra != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm + 4,
              CsSpace.md,
              0,
            ),
            child: extra,
          ),
        if (summary != null)
          Padding(
            padding: side.add(const EdgeInsets.only(top: CsSpace.sm + 2)),
            child: summary,
          ),
        Padding(
          padding: side.add(const EdgeInsets.only(top: CsSpace.sm)),
          child: Divider(height: 1, thickness: 1, color: cs.border),
        ),
        actions,
        const SizedBox(height: CsSpace.xs),
      ],
    );
    if (!framed) return body;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: body),
    );
  }
}

/// "What's happening on campus?": opens the composer, with quick buttons
/// for a photo, a question, a poll and an issue.
class CsComposerPrompt extends StatelessWidget {
  const CsComposerPrompt({
    super.key,
    required this.avatar,
    required this.hint,
    required this.onTap,
    this.actions = const [],
  });

  final Widget avatar;
  final String hint;
  final VoidCallback onTap;
  final List<CsComposerAction> actions;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm + 4,
              CsSpace.md,
              CsSpace.sm,
            ),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: CsSpace.sm + 2),
                Expanded(
                  child: Semantics(
                    button: true,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(CsRadius.full),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CsSpace.md,
                          vertical: CsSpace.sm + 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(CsRadius.full),
                        ),
                        child: Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyLarge?.copyWith(
                            color: cs.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: cs.border),
            Row(
              children: [
                for (final a in actions)
                  Expanded(
                    child: InkWell(
                      onTap: a.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: CsSpace.sm + 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(a.icon, size: 20, color: a.color),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                a.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.labelLarge?.copyWith(
                                  color: cs.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A quick button of [CsComposerPrompt].
class CsComposerAction {
  const CsComposerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// The colour of a reaction's label once given (wire names from the API);
/// lighter on dark cards so the label stays readable.
abstract final class CsReactionStyle {
  static Color color(BuildContext context, String reaction) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (reaction) {
      'like' => dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
      'haha' ||
      'wow' ||
      'sad' ||
      'clap' => dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      _ => context.cs.primary,
    };
  }
}
