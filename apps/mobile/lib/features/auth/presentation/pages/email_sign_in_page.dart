import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/email_sign_in_bloc.dart';
import '../email_error_text.dart';
import '../widgets/notice_banner.dart';

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
      appBar: AppBar(
        title: Text(l10n.emailSignInTitle, style: context.text.titleSmall),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.lg,
              CsSpace.md,
              CsSpace.lg,
              CsSpace.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CsSize.contentMaxWidth,
              ),
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
          _StepHeader(
            icon: CsIcons.emailAt,
            title: l10n.emailStepTitle,
            subtitle: l10n.emailStepSubtitle,
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
              prefixIcon: const Icon(CsIcons.email),
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
          _StepHeader(
            icon: CsIcons.emailSent,
            title: l10n.codeStepTitle,
            subtitle: l10n.codeSentTo(state.email),
          ),
          if (state.university != null) ...[
            const SizedBox(height: CsSpace.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CsBadge(
                icon: CsIcons.academic,
                label: state.university!.localName(lang),
              ),
            ),
          ],
          const SizedBox(height: CsSpace.lg),
          CsCodeField(
            controller: _controller,
            enabled: !busy,
            hasError: state.failure != null,
            semanticLabel: l10n.codeLabel,
            onCompleted: (_) => _submit(), // no extra tap needed
          ),
          AnimatedSize(
            duration: CsMotion.normal,
            curve: CsMotion.curve,
            child: state.failure == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: CsSpace.md),
                    child: NoticeBanner(
                      text: emailErrorText(l10n, state.failure!),
                    ),
                  ),
          ),
          const SizedBox(height: CsSpace.lg),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy ? const _Spinner() : Text(l10n.verifyCode),
          ),
          const SizedBox(height: CsSpace.md),
          OutlinedButton.icon(
            onPressed: busy || state.resendIn > 0
                ? null
                : () => bloc.add(const ResendRequested()),
            icon: const Icon(CsIcons.refresh),
            label: Text(
              state.resendIn > 0
                  ? l10n.resendCodeIn(countdownText(state.resendIn))
                  : l10n.resendCode,
            ),
          ),
          const SizedBox(height: CsSpace.xs),
          TextButton(
            onPressed: busy
                ? null
                : () => bloc.add(const EmailChangeRequested()),
            child: Text(l10n.useDifferentEmail),
          ),
          const SizedBox(height: CsSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CsIcons.info, size: 16, color: context.cs.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(l10n.codeSpamHint, style: context.text.bodySmall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Icon tile, title and explanation at the top of each step.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(CsRadius.md + 2),
          ),
          child: Icon(icon, color: cs.onPrimaryContainer, size: 28),
        ),
        const SizedBox(height: CsSpace.lg),
        Text(title, style: context.text.headlineSmall),
        const SizedBox(height: CsSpace.sm),
        Text(
          subtitle,
          style: context.text.bodyLarge?.copyWith(color: cs.textSecondary),
        ),
      ],
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
