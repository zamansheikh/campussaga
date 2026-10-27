import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_form_cubit.dart';
import '../widgets/profile_form.dart';

/// Shown after sign-in while name, department or batch is missing. Saving
/// (or "Later") lets the router open the app.
class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthBloc>();
    final user = auth.state.user;
    if (user == null) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => ProfileFormCubit(getIt<ProfileRepository>()),
      child: Scaffold(
        body: SafeArea(
          child: CsPage(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.lg,
              CsSpace.xl,
              CsSpace.lg,
              CsSpace.lg,
            ),
            children: [
              Row(
                children: [
                  CsAvatar(name: user.displayName ?? user.email, size: 56),
                  const Spacer(),
                  CsBadge(
                    label: l10n.setupProfileStep,
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.lg),
              Text(l10n.setupProfileTitle, style: context.text.headlineSmall),
              const SizedBox(height: CsSpace.sm),
              Text(
                l10n.setupProfileSubtitle,
                style: context.text.bodyLarge?.copyWith(
                  color: context.cs.textSecondary,
                ),
              ),
              const SizedBox(height: CsSpace.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CsBadge(
                  label: user.university.localName(lang),
                  icon: Icons.account_balance_outlined,
                  tone: CsBadgeTone.neutral,
                ),
              ),
              const SizedBox(height: CsSpace.lg),
              ProfileForm(
                initial: user,
                onSaved: (u) => auth.add(AuthProfileUpdated(u)),
                secondary: TextButton(
                  onPressed: () => auth.add(const AuthProfileSetupSkipped()),
                  child: Text(l10n.setupLater),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
