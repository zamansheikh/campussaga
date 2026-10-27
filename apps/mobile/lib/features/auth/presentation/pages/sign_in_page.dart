import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/env.dart';
import '../../../../app/router.dart';

import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';

/// First screen for signed-out students.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CsSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final busy = state.status == AuthStatus.signingIn;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.school_rounded, size: 56, color: cs.primary),
                      const SizedBox(height: CsSpace.md),
                      Text(
                        l10n.appName,
                        textAlign: TextAlign.center,
                        style: context.text.displaySmall,
                      ),
                      const SizedBox(height: CsSpace.xl),
                      Text(
                        l10n.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: context.text.titleMedium,
                      ),
                      const SizedBox(height: CsSpace.sm),
                      Text(
                        l10n.welcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                      const SizedBox(height: CsSpace.xl),
                      if (state.failure != null) ...[
                        _ErrorBanner(text: authErrorText(l10n, state.failure!)),
                        const SizedBox(height: CsSpace.md),
                      ],
                      // TODO(release): use Google's branded button assets
                      // (Google sign-in branding guidelines).
                      FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => context.read<AuthBloc>().add(
                                const AuthGoogleRequested(),
                              ),
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(l10n.continueWithGoogle),
                      ),
                      const SizedBox(height: CsSpace.sm),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => context.push(Routes.signInEmail),
                        child: Text(l10n.useUniversityEmail),
                      ),
                      const SizedBox(height: CsSpace.md),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(Env.privacyPolicyUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(l10n.privacyPolicy),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(CsSpace.md),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(CsRadius.md),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: CsSpace.sm),
            Expanded(child: Text(text, style: context.text.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
