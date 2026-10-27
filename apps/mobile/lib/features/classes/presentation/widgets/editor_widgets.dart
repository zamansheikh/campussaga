import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../class_format.dart';

/// A tappable start/end time (opens the time picker).
class TimeBox extends StatelessWidget {
  const TimeBox({
    super.key,
    required this.label,
    required this.minutes,
    required this.onTap,
    this.error = false,
  });

  final String label;
  final int minutes;
  final VoidCallback? onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.md),
        side: BorderSide(color: error ? cs.error : cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: cs.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.labelMedium),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        clockText(context, minutes),
                        style: context.text.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Course suggestions under a course-code field.
class CourseOptions extends StatelessWidget {
  const CourseOptions({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final Iterable<ClassSlot> options;
  final AutocompleteOnSelected<ClassSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: CsSpace.xs),
        child: Material(
          elevation: 6,
          shadowColor: Colors.black26,
          color: context.cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CsRadius.md),
            side: BorderSide(color: context.cs.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: CsSpace.xs),
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    title: Text(o.courseCode),
                    subtitle: o.courseTitle.isEmpty
                        ? null
                        : Text(o.courseTitle),
                    onTap: () => onSelected(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
