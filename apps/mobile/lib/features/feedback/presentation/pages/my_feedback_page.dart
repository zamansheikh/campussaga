import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../classes/presentation/class_format.dart';
import '../../../verification/presentation/widgets/load_view.dart';
import '../feedback_text.dart';

/// The student's feedback, newest activity first, with its status and an
/// unread dot when the team has written.
class MyFeedbackPage extends StatelessWidget {
  const MyFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackMine)),
      body: SafeArea(
        child: LoadView<List<FeedbackEntry>>(
          load: () => getIt<FeedbackRepository>().mine(),
          builder: (context, items, reload) => items.isEmpty
              ? CsEmptyState(
                  icon: CsIcons.comment,
                  title: l10n.feedbackEmpty,
                  message: l10n.feedbackEmptyBody,
                  actionLabel: l10n.feedbackSend,
                  onAction: () async {
                    await context.push(Routes.feedbackSend);
                    await reload();
                  },
                )
              : RefreshIndicator(
                  onRefresh: reload,
                  child: CsPage(
                    children: [
                      CsSection(
                        children: [
                          for (final f in items)
                            _FeedbackRow(
                              entry: f,
                              onTap: () async {
                                await context.push(Routes.feedbackThread(f.id));
                                await reload();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.entry, required this.onTap});

  final FeedbackEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final when = entry.lastMessageAt ?? entry.createdAt;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(CsSpace.md),
        child: Row(
          children: [
            if (entry.unread)
              Semantics(
                label: l10n.feedbackStatusNew,
                child: Container(
                  key: const ValueKey('unread-dot'),
                  width: 10,
                  height: 10,
                  margin: const EdgeInsetsDirectional.only(end: CsSpace.sm),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: entry.unread ? FontWeight.w700 : null,
                    ),
                  ),
                  const SizedBox(height: CsSpace.xs),
                  Text(
                    [
                      feedbackKindLabel(l10n, entry.kind),
                      if (when != null) agoText(context, when, appNow()),
                    ].join(' · '),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: CsSpace.sm),
            CsPill(
              label: feedbackStatusLabel(l10n, entry.status),
              highlight: !entry.status.closed,
            ),
          ],
        ),
      ),
    );
  }
}
