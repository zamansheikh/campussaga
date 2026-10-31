import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../verification_text.dart';
import '../widgets/load_view.dart';

/// A classmate's vouch link (https://varsitykotha.com/v/{code}): who is
/// asking, and a button to say "I know them" (docs/CAMPUS_ADMINS.md §4).
class VouchPage extends StatelessWidget {
  const VouchPage({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vouchTitle)),
      body: SafeArea(
        child: LoadView<VouchCard>(
          load: () => getIt<VerificationRepository>().vouchCard(code),
          builder: (context, card, reload) =>
              _VouchView(code: code, first: card),
        ),
      ),
    );
  }
}

class _VouchView extends StatefulWidget {
  const _VouchView({required this.code, required this.first});

  final String code;
  final VouchCard first;

  @override
  State<_VouchView> createState() => _VouchViewState();
}

class _VouchViewState extends State<_VouchView> {
  late VouchCard _card = widget.first;
  bool _busy = false;

  /// Set after vouching: the thank-you line.
  String? _thanks;

  /// Why vouching failed, in plain words.
  String? _problem;

  Future<void> _vouch() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final next = await getIt<VerificationRepository>().vouch(widget.code);
      if (!mounted) return;
      setState(() {
        _card = next;
        _thanks = next.verified
            ? l10n.vouchNowVerified(next.student.name)
            : l10n.vouchThanksMore(next.remaining);
      });
    } on Failure catch (f) {
      if (mounted) {
        setState(
          () => _problem = verificationErrorText(
            l10n,
            f,
            name: _card.student.name,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final c = _card;
    final s = c.student;
    final Widget action;
    if (_thanks != null) {
      action = _Note(icon: CsIcons.checkCircle, text: _thanks!);
    } else if (c.verified) {
      action = _Note(
        icon: CsIcons.verified,
        text: l10n.vouchReasonAlreadyVerified(s.name),
      );
    } else if (c.alreadyVouched) {
      action = _Note(icon: CsIcons.checkCircle, text: l10n.vouchAlready);
    } else if (c.canVouch) {
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _busy ? null : _vouch,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.vouchButton(c.universityName)),
          ),
          const SizedBox(height: CsSpace.sm),
          Text(
            l10n.vouchCareHint,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
          ),
        ],
      );
    } else {
      action = NoticeBanner(
        text: c.reason == null
            ? l10n.errorGeneric
            : vouchReasonText(l10n, c.reason!, s.name),
      );
    }
    return CsPage(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(CsSpace.lg),
            child: Column(
              children: [
                UserAvatar(
                  userId: s.id,
                  name: s.name,
                  photoVersion: s.photoVersion,
                  googlePhotoUrl: s.googlePhotoUrl,
                  size: 72,
                ),
                const SizedBox(height: CsSpace.md),
                Text(
                  s.name,
                  style: context.text.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (s.classLine.isNotEmpty) ...[
                  const SizedBox(height: CsSpace.xs),
                  Text(
                    s.classLine,
                    style: context.text.bodyMedium?.copyWith(
                      color: cs.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: CsSpace.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: CsSpace.sm,
                  runSpacing: CsSpace.sm,
                  children: [
                    CsPill(icon: CsIcons.university, label: c.universityName),
                    CsPill(
                      icon: CsIcons.verifiedOutline,
                      label: l10n.verifyProgress(c.vouches, c.needed),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CsSpace.lg),
        if (_problem != null) ...[
          NoticeBanner(text: _problem!),
          const SizedBox(height: CsSpace.md),
        ],
        action,
      ],
    );
  }
}

/// A calm confirmation line with an icon.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(CsRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
