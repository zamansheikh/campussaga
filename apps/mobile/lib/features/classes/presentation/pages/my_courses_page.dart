import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

/// Which of the group's courses are in the student's own routine (e.g. a
/// retake student keeps only the one course they take in this section).
class MyCoursesPage extends StatelessWidget {
  const MyCoursesPage({super.key, required this.groupId});

  final String groupId;

  Future<void> _toggle(
    BuildContext context,
    ClassGroup g,
    String code,
    bool on,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final key = courseKey(code);
    final hidden = {...g.hiddenCourses};
    on ? hidden.remove(key) : hidden.add(key);
    try {
      await context.read<MyClassesCubit>().setHiddenCourses(g.id, hidden);
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = context.select((MyClassesCubit c) => c.state.group(groupId));
    if (g == null) return const Scaffold(body: SizedBox.shrink());
    final courses = <String, ClassSlot>{};
    for (final s in g.slots) {
      courses.putIfAbsent(courseKey(s.courseCode), () => s);
    }
    final list = courses.values.toList()
      ..sort((a, b) => a.courseCode.compareTo(b.courseCode));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myCourses)),
      body: CsPage(
        children: [
          Text(
            l10n.myCoursesHint,
            style: context.text.bodyMedium?.copyWith(
              color: context.cs.textSecondary,
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          if (list.isEmpty)
            Text(l10n.noClassesYetMember, style: context.text.bodyMedium)
          else
            CsSection(
              title: g.title,
              children: [
                for (final c in list)
                  CsRow(
                    icon: Icons.menu_book_outlined,
                    title: c.courseCode,
                    subtitle: c.courseTitle.isEmpty ? null : c.courseTitle,
                    showChevron: false,
                    trailing: Switch(
                      value: !g.hides(c.courseCode),
                      onChanged: (on) => _toggle(context, g, c.courseCode, on),
                    ),
                    onTap: () => _toggle(
                      context,
                      g,
                      c.courseCode,
                      g.hides(c.courseCode),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
