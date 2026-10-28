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
import '../widgets/google_button.dart';
import '../widgets/notice_banner.dart';

/// First screen for signed-out students: brand on top, sign-in below.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Scaffold(
      body: Stack(
        children: [
          // Soft brand glow behind the logo.
          Positioned(
            top: -180,
            left: -120,
            right: -120,
            child: Container(
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primaryContainer,
                    cs.primaryContainer.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  CsSpace.lg,
                  CsSpace.xl,
                  CsSpace.lg,
                  CsSpace.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    // At least the screen's height, so the brand sits in
                    // the middle and sign-in at the bottom; scrolls when
                    // the text is large.
                    constraints: BoxConstraints(
                      maxWidth: CsSize.contentMaxWidth,
                      minHeight: viewport.maxHeight - CsSpace.xl - CsSpace.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox.shrink(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: CsBrandMark(size: 76)),
                            const SizedBox(height: CsSpace.lg),
                            Text(
                              l10n.appName,
                              textAlign: TextAlign.center,
                              style: context.text.displaySmall,
                            ),
                            const SizedBox(height: CsSpace.sm),
                            Text(
                              l10n.signInTagline,
                              textAlign: TextAlign.center,
                              style: context.text.bodyLarge?.copyWith(
                                color: cs.textSecondary,
                              ),
                            ),
                            const SizedBox(height: CsSpace.xl),
                          ],
                        ),
                        const _SignInPanel(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInPanel extends StatelessWidget {
  const _SignInPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final busy = state.status == AuthStatus.signingIn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.welcomeTitle,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: CsSpace.xs),
            Text(
              l10n.welcomeSubtitle,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: CsSpace.lg),
            AnimatedSize(
              duration: CsMotion.normal,
              curve: CsMotion.curve,
              child: state.failure == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: CsSpace.md),
                      child: NoticeBanner(
                        text: authErrorText(l10n, state.failure!),
                      ),
                    ),
            ),
            GoogleButton(
              label: l10n.continueWithGoogle,
              busy: busy,
              onPressed: busy
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const AuthGoogleRequested(),
                    ),
            ),
            const SizedBox(height: CsSpace.md),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
                  child: Text(l10n.orDivider, style: context.text.bodySmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            OutlinedButton.icon(
              onPressed: busy ? null : () => context.push(Routes.signInEmail),
              icon: const Icon(CsIcons.email),
              label: Text(l10n.useUniversityEmail),
            ),
            const SizedBox(height: CsSpace.lg),
            const _LegalLine(),
          ],
        );
      },
    );
  }
}

/// "By continuing, you agree to our Privacy policy." with a tappable link.
class _LegalLine extends StatelessWidget {
  const _LegalLine();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const marker = '\u0000';
    final parts = l10n.signInLegal(marker).split(marker);
    final style = context.text.bodySmall;
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: style,
        children: [
          TextSpan(text: parts.first),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Semantics(
              link: true,
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(Env.privacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  l10n.privacyPolicy,
                  style: style?.copyWith(
                    color: context.cs.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: context.cs.primary,
                  ),
                ),
              ),
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts.last),
        ],
      ),
    );
  }
}
