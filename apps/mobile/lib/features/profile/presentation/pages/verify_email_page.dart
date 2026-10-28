import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/email_error_text.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';

/// A student who signed in with Gmail proves a university email with a
/// 6-digit code and becomes verified (at that email's university). A
/// verified student uses the same page to move to another university.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  CodeSent? _sent;
  Failure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await fn();
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
    final sent = await getIt<ProfileRepository>().requestVerifyCode(
      _email.text,
    );
    if (mounted) setState(() => _sent = sent);
  });

  Future<void> _verify(String code) => _run(() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = await getIt<ProfileRepository>().verifyUniversityEmail(
        _sent!.email,
        code,
      );
      final moving = auth.state.user?.verified ?? false;
      auth.add(AuthProfileUpdated(user));
      messenger.showSnackBar(
        SnackBar(
          content: Text(moving ? l10n.universityChanged : l10n.verifiedNow),
        ),
      );
      if (mounted) context.pop();
    } on Failure {
      _code.clear();
      rethrow;
    }
  });

  String _error(AppLocalizations l10n, Failure f) => switch (f) {
    RejectedFailure(code: 'UNIVERSITY_EMAIL_REQUIRED') =>
      l10n.errorNotUniversityEmailVerify,
    _ => emailErrorText(l10n, f),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final lang = Localizations.localeOf(context).languageCode;
    final sent = _sent;
    final moving = context.select(
      (AuthBloc b) => b.state.user?.verified ?? false,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(moving ? l10n.changeUniversity : l10n.verifyTitle),
      ),
      body: SafeArea(
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            CsSpace.sm,
            CsSpace.lg,
            CsSpace.lg,
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(CsRadius.md + 2),
                ),
                child: Icon(
                  CsIcons.verifiedOutline,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: CsSpace.lg),
            Text(
              sent != null
                  ? l10n.codeSentTo(sent.email)
                  : moving
                  ? l10n.changeUniversitySubtitle
                  : l10n.verifySubtitle,
              style: context.text.bodyLarge?.copyWith(color: cs.textSecondary),
            ),
            if (sent?.university case final uni?) ...[
              const SizedBox(height: CsSpace.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CsBadge(
                  icon: CsIcons.academic,
                  label: uni.localName(lang),
                ),
              ),
            ],
            const SizedBox(height: CsSpace.lg),
            if (sent == null) ...[
              TextField(
                controller: _email,
                enabled: !_busy,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  hintText: l10n.emailHint,
                  prefixIcon: const Icon(CsIcons.email),
                ),
              ),
            ] else
              CsCodeField(
                controller: _code,
                enabled: !_busy,
                hasError: _failure != null,
                semanticLabel: l10n.codeLabel,
                onCompleted: _verify,
              ),
            if (_failure != null) ...[
              const SizedBox(height: CsSpace.md),
              NoticeBanner(text: _error(l10n, _failure!)),
            ],
            const SizedBox(height: CsSpace.lg),
            if (sent == null)
              FilledButton(
                onPressed: _busy ? null : _send,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.sendCode),
              )
            else ...[
              FilledButton(
                onPressed: _busy || _code.text.length < 6
                    ? null
                    : () => _verify(_code.text),
                child: Text(l10n.verifyCode),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _sent = null;
                        _failure = null;
                        _code.clear();
                      }),
                child: Text(l10n.useDifferentEmail),
              ),
              Text(
                l10n.codeSpamHint,
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
