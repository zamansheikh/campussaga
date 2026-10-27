import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/settings/bloc/settings_cubit.dart';
import '../../auth/presentation/auth_error_text.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';

/// Account (edit profile, sign out, delete account) and settings.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final controller = context.read<SettingsCubit>();

    return BlocListener<AuthBloc, AuthState>(
      // Deleting failed (e.g. offline): still signed in, say why.
      listenWhen: (a, b) =>
          a.deleting && !b.deleting && b.status == AuthStatus.signedIn,
      listener: (context, s) {
        if (s.failure == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorText(l10n, s.failure!))),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.navProfile)),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: CsSpace.sm),
          children: [
            _SectionLabel(l10n.account),
            const _AccountCard(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editProfile),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.editProfile),
            ),
            _SectionLabel(l10n.settings),
            _Group(
              title: l10n.theme,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => controller.setThemeMode(s.first),
              ),
            ),
            _Group(
              title: l10n.language,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'system', label: Text(l10n.themeSystem)),
                  const ButtonSegment(value: 'en', label: Text('English')),
                  const ButtonSegment(value: 'bn', label: Text('বাংলা')),
                ],
                selected: {settings.locale?.languageCode ?? 'system'},
                onSelectionChanged: (s) => controller.setLocale(
                  s.first == 'system' ? null : Locale(s.first),
                ),
              ),
            ),
            const SizedBox(height: CsSpace.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CsSpace.screen),
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut),
              ),
            ),
            const SizedBox(height: CsSpace.sm),
            const _DeleteAccountButton(),
            const SizedBox(height: CsSpace.lg),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: context.cs.error),
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.cs.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (ok ?? false) auth.add(const AuthAccountDeleteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deleting = context.select((AuthBloc b) => b.state.deleting);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.screen),
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: context.cs.error),
        onPressed: deleting ? null : () => _confirm(context),
        icon: deleting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_forever_outlined),
        label: Text(l10n.deleteAccount),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    final name = user.displayName ?? user.email.split('@').first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.screen),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: context.cs.primaryContainer,
            foregroundColor: context.cs.onPrimaryContainer,
            child: Text(name.characters.first.toUpperCase()),
          ),
          title: Text(name),
          subtitle: Text(
            [
              user.email,
              user.university.localName(lang),
              [
                user.department,
                user.batch,
              ].where((v) => v != null && v.isNotEmpty).join(' · '),
            ].where((v) => v.isNotEmpty).join('\n'),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CsSpace.screen,
        CsSpace.md,
        CsSpace.screen,
        CsSpace.sm,
      ),
      child: Text(text, style: context.text.labelLarge),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CsSpace.screen,
        vertical: CsSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.bodyMedium),
          const SizedBox(height: CsSpace.sm),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
