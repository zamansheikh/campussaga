import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/email_sign_in_bloc.dart';
import '../email_error_text.dart';

/// Sign in with a university email: enter email → enter the 6-digit code.
class EmailSignInPage extends StatelessWidget {
  const EmailSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmailSignInBloc(repository: getIt<AuthRepository>()),
      child: BlocListener<EmailSignInBloc, EmailSignInState>(
        listenWhen: (a, b) => b.status == EmailSignInStatus.success,
        // AuthBloc switches to signed-in; the router then opens the app.
        listener: (context, state) =>
            context.read<AuthBloc>().add(AuthSignedIn(state.result!)),
        child: const _EmailSignInView(),
      ),
    );
  }
}

class _EmailSignInView extends StatelessWidget {
  const _EmailSignInView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = context.select((EmailSignInBloc b) => b.state.step);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.emailSignInTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CsSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: CsMotion.normal,
                child: step == EmailSignInStep.email
                    ? const _EmailStep(key: ValueKey('email'))
                    : const _CodeStep(key: ValueKey('code')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailStep extends StatefulWidget {
  const _EmailStep({super.key});

  @override
  State<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<_EmailStep> {
  late final _controller = TextEditingController(
    text: context.read<EmailSignInBloc>().state.email,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<EmailSignInBloc>().add(EmailSubmitted(_controller.text));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<EmailSignInBloc>().state;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.emailStepTitle, style: context.text.headlineSmall),
          const SizedBox(height: CsSpace.sm),
          Text(
            l10n.emailStepSubtitle,
            style: context.text.bodyMedium?.copyWith(
              color: context.cs.textSecondary,
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !state.busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              hintText: l10n.emailHint,
              errorText: state.failure == null
                  ? null
                  : emailErrorText(l10n, state.failure!),
              errorMaxLines: 3,
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          FilledButton(
            onPressed: state.busy ? null : _submit,
            child: state.busy ? const _Spinner() : Text(l10n.sendCode),
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep({super.key});

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<EmailSignInBloc>().add(CodeSubmitted(_controller.text));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final bloc = context.read<EmailSignInBloc>();
    final state = context.watch<EmailSignInBloc>().state;
    final busy = state.busy || state.status == EmailSignInStatus.success;

    return BlocListener<EmailSignInBloc, EmailSignInState>(
      // A wrong or expired code: clear the field for the next try.
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, state) => _controller.clear(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.codeStepTitle, style: context.text.headlineSmall),
          const SizedBox(height: CsSpace.sm),
          Text(
            l10n.codeSentTo(state.email),
            style: context.text.bodyMedium?.copyWith(
              color: context.cs.textSecondary,
            ),
          ),
          if (state.university != null) ...[
            const SizedBox(height: CsSpace.sm),
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: context.cs.primary,
                ),
                const SizedBox(width: CsSpace.xs),
                Expanded(
                  child: Text(
                    state.university!.localName(lang),
                    style: context.text.labelLarge,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: CsSpace.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !busy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(letterSpacing: 12),
            onChanged: (v) {
              if (v.length == 6) _submit(); // no extra tap needed
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.codeLabel,
              counterText: '',
              errorText: state.failure == null
                  ? null
                  : emailErrorText(l10n, state.failure!),
              errorMaxLines: 3,
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy ? const _Spinner() : Text(l10n.verifyCode),
          ),
          const SizedBox(height: CsSpace.sm),
          TextButton(
            onPressed: busy || state.resendIn > 0
                ? null
                : () => bloc.add(const ResendRequested()),
            child: Text(
              state.resendIn > 0
                  ? l10n.resendCodeIn(countdownText(state.resendIn))
                  : l10n.resendCode,
            ),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => bloc.add(const EmailChangeRequested()),
            child: Text(l10n.useDifferentEmail),
          ),
          const SizedBox(height: CsSpace.sm),
          Text(
            l10n.codeSpamHint,
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
