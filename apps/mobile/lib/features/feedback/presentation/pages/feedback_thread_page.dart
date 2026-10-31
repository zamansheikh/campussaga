import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';
import '../../../classes/presentation/class_format.dart';
import '../../../verification/presentation/verification_text.dart';
import '../../../verification/presentation/widgets/load_view.dart';
import '../feedback_text.dart';

/// One piece of feedback as a conversation: the original, the team's
/// answers and a reply box.
class FeedbackThreadPage extends StatelessWidget {
  const FeedbackThreadPage({super.key, required this.feedbackId});

  final String feedbackId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackTitle)),
      body: SafeArea(
        child: LoadView<FeedbackThread>(
          load: () => getIt<FeedbackRepository>().thread(feedbackId),
          builder: (context, thread, reload) => _ThreadView(thread: thread),
        ),
      ),
    );
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView({required this.thread});

  final FeedbackThread thread;

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _reply = TextEditingController();
  late final List<FeedbackMessage> _messages = [...widget.thread.messages];
  bool _sending = false;
  String? _problem;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _problem = null;
    });
    try {
      final m = await getIt<FeedbackRepository>().reply(
        widget.thread.feedback.id,
        text,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(m);
        _reply.clear();
      });
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _problem = verificationErrorText(l10n, f));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = widget.thread.feedback;
    return Column(
      children: [
        Expanded(
          child: CsPage(
            children: [
              Wrap(
                spacing: CsSpace.sm,
                runSpacing: CsSpace.sm,
                children: [
                  CsPill(label: feedbackKindLabel(l10n, f.kind)),
                  CsPill(label: feedbackStatusLabel(l10n, f.status)),
                ],
              ),
              const SizedBox(height: CsSpace.md),
              _Bubble(
                who: l10n.feedbackYou,
                body: f.message,
                at: f.createdAt,
                team: false,
                images: f.images,
              ),
              for (final m in _messages)
                _Bubble(
                  who: m.fromTeam ? l10n.feedbackTeam : l10n.feedbackYou,
                  body: m.body,
                  at: m.createdAt,
                  team: m.fromTeam,
                ),
              if (f.status.closed) ...[
                const SizedBox(height: CsSpace.sm),
                Text(l10n.feedbackClosedNote, style: context.text.bodySmall),
              ],
            ],
          ),
        ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
            child: NoticeBanner(text: _problem!),
          ),
        Padding(
          padding: const EdgeInsets.all(CsSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _reply,
                  enabled: !_sending,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: FeedbackDraft.maxLength,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: l10n.feedbackReplyHint),
                ),
              ),
              const SizedBox(width: CsSpace.sm),
              IconButton.filled(
                tooltip: l10n.feedbackReplySend,
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CsIcons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One message: the team's on one side, the student's on the other.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.who,
    required this.body,
    required this.team,
    this.at,
    this.images = const [],
  });

  final String who;
  final String body;
  final bool team;
  final DateTime? at;
  final List<FeedbackImage> images;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Align(
      alignment: team
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: CsSpace.sm),
        padding: const EdgeInsets.all(CsSpace.md),
        decoration: BoxDecoration(
          color: team ? cs.surfaceVariant : cs.primaryContainer,
          borderRadius: BorderRadius.circular(CsRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                who,
                if (at != null) agoText(context, at!, appNow()),
              ].join(' · '),
              style: context.text.labelSmall?.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: CsSpace.xs),
            Text(body, style: context.text.bodyMedium),
            if (images.isNotEmpty) ...[
              const SizedBox(height: CsSpace.sm),
              Wrap(
                spacing: CsSpace.sm,
                runSpacing: CsSpace.sm,
                children: [for (final i in images) _Shot(image: i)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An attached screenshot, loaded with the student's sign-in.
class _Shot extends StatelessWidget {
  const _Shot({required this.image});

  final FeedbackImage image;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CsRadius.sm),
      child: SizedBox(
        width: 96,
        height: 96,
        child: FutureBuilder<Uint8List>(
          future: getIt<FeedbackRepository>().image(image.thumbUrl),
          builder: (context, snap) {
            final bytes = snap.data;
            if (bytes != null) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(color: cs.surfaceVariant),
              );
            }
            return ColoredBox(
              color: cs.surfaceVariant,
              child: snap.hasError
                  ? Icon(CsIcons.imageBroken, color: cs.textSecondary)
                  : null,
            );
          },
        ),
      ),
    );
  }
}
