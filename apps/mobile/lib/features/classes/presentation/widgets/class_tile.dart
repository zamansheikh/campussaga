import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../class_format.dart';

/// A steady colour per course, so the same course looks the same everywhere.
Color courseColor(String courseCode) {
  const colors = [
    Color(0xFF0D9488),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFF22C55E),
    Color(0xFFEF4444),
  ];
  final key = courseCode.toUpperCase().replaceAll(' ', '');
  return colors[key.codeUnits.fold<int>(
        7,
        (a, b) => (a * 31 + b) & 0x7fffffff,
      ) %
      colors.length];
}

/// One class in a list: time, course colour, code and title, room/teacher.
/// With [item] (a class on a date) it shows that date's change: crossed
/// out when cancelled, the new time and room when changed, the CR's note.
class ClassTile extends StatelessWidget {
  const ClassTile({
    super.key,
    required this.slot,
    this.item,
    this.groupTitle,
    this.overline,
    this.onTap,
    this.state = ClassTileState.normal,
  });

  ClassTile.on(
    ClassOnDay this.item, {
    super.key,
    this.groupTitle,
    this.overline,
    this.onTap,
    this.state = ClassTileState.normal,
  }) : slot = item.slot;

  final ClassSlot slot;
  final ClassOnDay? item;

  /// Shown when the student is in more than one group.
  final String? groupTitle;

  /// A small line above the course code (e.g. the date).
  final String? overline;
  final VoidCallback? onTap;
  final ClassTileState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final it = item;
    final cancelled = it?.cancelled ?? false;
    final start = it?.startMin ?? slot.startMin;
    final end = it?.endMin ?? slot.endMin;
    final room = it?.room ?? slot.room;
    final note = it?.change?.note ?? '';
    final past = state == ClassTileState.past || cancelled;
    final strike = cancelled
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    final meta = [
      if (room.isNotEmpty) l10n.roomShort(room),
      if (slot.teacher.isNotEmpty) slot.teacher,
      ?groupTitle,
    ].join(' · ');
    final changedColor = it != null && it.moved ? cs.statusInProgress.fg : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CsSpace.md,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: past ? 0.55 : 1,
              child: SizedBox(
                width: 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Fit(
                      Text(
                        clockText(context, start),
                        style: context.text.labelLarge
                            ?.merge(strike)
                            .copyWith(color: changedColor),
                      ),
                    ),
                    _Fit(
                      Text(
                        clockText(context, end),
                        style: context.text.bodySmall?.merge(strike),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 4,
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: courseColor(slot.courseCode)
                    .withValues(alpha: past ? 0.4 : 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overline != null)
                    Text(
                      overline!,
                      style: context.text.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Opacity(
                        opacity: past ? 0.55 : 1,
                        child: Text(
                          slot.courseCode,
                          style: context.text.titleSmall?.merge(strike),
                        ),
                      ),
                      if (cancelled)
                        CsBadge(
                          label: l10n.changeCancelled,
                          tone: CsBadgeTone.danger,
                        ),
                      if (it != null && it.moved)
                        CsBadge(
                          label: l10n.changeMoved,
                          tone: CsBadgeTone.accent,
                        ),
                      if (it != null && it.extra)
                        CsBadge(label: l10n.changeExtra),
                      if (slot.kind == ClassKind.lab)
                        CsBadge(label: l10n.classLab, tone: CsBadgeTone.accent),
                      if (state == ClassTileState.now && !cancelled)
                        CsBadge(
                          label: l10n.nowInClass,
                          tone: CsBadgeTone.success,
                        ),
                    ],
                  ),
                  Opacity(
                    opacity: past ? 0.55 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (slot.courseTitle.isNotEmpty)
                          Text(
                            slot.courseTitle,
                            style: context.text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (meta.isNotEmpty)
                          Text(
                            meta,
                            style: context.text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: cs.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              note,
                              style: context.text.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: cs.textSecondary),
          ],
        ),
      ),
    );
  }
}

enum ClassTileState { normal, past, now }

/// Shrinks a long time label (large text settings) instead of overflowing.
class _Fit extends StatelessWidget {
  const _Fit(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}

/// Rows on one card with dividers, without section title spacing.
class ClassList extends StatelessWidget {
  const ClassList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CsSection(children: children);
}
