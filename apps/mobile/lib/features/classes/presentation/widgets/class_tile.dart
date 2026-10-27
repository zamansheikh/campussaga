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
class ClassTile extends StatelessWidget {
  const ClassTile({
    super.key,
    required this.slot,
    this.groupTitle,
    this.onTap,
    this.state = ClassTileState.normal,
  });

  final ClassSlot slot;

  /// Shown when the student is in more than one group.
  final String? groupTitle;
  final VoidCallback? onTap;
  final ClassTileState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final past = state == ClassTileState.past;
    final meta = [
      if (slot.room.isNotEmpty) l10n.roomShort(slot.room),
      if (slot.teacher.isNotEmpty) slot.teacher,
      ?groupTitle,
    ].join(' · ');
    return Opacity(
      opacity: past ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CsSpace.md,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Fit(
                      Text(
                        clockText(context, slot.startMin),
                        style: context.text.labelLarge,
                      ),
                    ),
                    _Fit(
                      Text(
                        clockText(context, slot.endMin),
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: courseColor(slot.courseCode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            slot.courseCode,
                            style: context.text.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (slot.kind == ClassKind.lab) ...[
                          const SizedBox(width: 6),
                          CsBadge(
                            label: l10n.classLab,
                            tone: CsBadgeTone.accent,
                          ),
                        ],
                        if (state == ClassTileState.now) ...[
                          const SizedBox(width: 6),
                          CsBadge(label: l10n.nowInClass),
                        ],
                      ],
                    ),
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
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: cs.textSecondary),
            ],
          ),
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
