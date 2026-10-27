import 'dart:async';

import 'package:campus_l10n/campus_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/email_sign_in_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/classes/presentation/pages/group_form_page.dart';
import '../features/classes/presentation/pages/group_page.dart';
import '../features/classes/presentation/pages/groups_page.dart';
import '../features/classes/presentation/pages/join_group_page.dart';
import '../features/classes/presentation/pages/slot_editor_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_setup_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/reminders/presentation/reminders_page.dart';
import '../features/routine/presentation/routine_page.dart';
import '../features/today/presentation/today_page.dart';
import 'settings/bloc/settings_cubit.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signInEmail = '/sign-in/email';
  static const setupProfile = '/setup-profile';
  static const today = '/today';
  static const routine = '/routine';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const reminders = '/profile/reminders';
  static const groups = '/groups';
  static const joinGroup = '/groups/join';
  static const newGroup = '/groups/new';
  static String group(String id) => '/groups/$id';
  static String editGroup(String id) => '/groups/$id/edit';
  static String newSlot(String groupId) => '/groups/$groupId/class/new';
  static String editSlot(String groupId, String slotId) =>
      '/groups/$groupId/class/$slotId';
}

/// App routes. Signed-out students see the welcome slides once, then only
/// the sign-in screens; signed-in students never see either.
GoRouter buildRouter(AuthBloc auth, SettingsCubit settings) {
  return GoRouter(
    initialLocation: Routes.today,
    refreshListenable: _StreamListenable([auth.stream, settings.stream]),
    redirect: (context, state) {
      final status = auth.state.status;
      final at = state.matchedLocation;
      if (status == AuthStatus.unknown) {
        return at == Routes.splash ? null : Routes.splash;
      }
      final atSignIn = at.startsWith(Routes.signIn);
      if (status != AuthStatus.signedIn) {
        if (!settings.state.onboardingDone) {
          return at == Routes.welcome ? null : Routes.welcome;
        }
        return atSignIn ? null : Routes.signIn;
      }
      if (at == Routes.welcome) return Routes.today;
      // Signed in: finish the profile first (unless "Later" was chosen).
      if (auth.state.needsProfileSetup) {
        return at == Routes.setupProfile ? null : Routes.setupProfile;
      }
      if (atSignIn || at == Routes.splash || at == Routes.setupProfile) {
        return Routes.today;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInPage(),
        routes: [
          GoRoute(
            path: 'email',
            builder: (context, state) => const EmailSignInPage(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.setupProfile,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      // Full-screen pages over the tabs.
      GoRoute(
        path: Routes.groups,
        builder: (context, state) => const GroupsPage(),
        routes: [
          GoRoute(
            path: 'join',
            builder: (context, state) => const JoinGroupPage(),
          ),
          GoRoute(
            path: 'new',
            builder: (context, state) => const GroupFormPage(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                GroupPage(groupId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    GroupFormPage(groupId: state.pathParameters['id']),
              ),
              GoRoute(
                path: 'class/new',
                builder: (context, state) =>
                    SlotEditorPage(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'class/:slotId',
                builder: (context, state) => SlotEditorPage(
                  groupId: state.pathParameters['id']!,
                  slotId: state.pathParameters['slotId'],
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.routine,
                builder: (context, state) => const RoutinePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'reminders',
                    builder: (context, state) => const RemindersPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Re-runs the router's redirect whenever auth or settings change.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(List<Stream<Object?>> streams) {
    _subs = [for (final s in streams) s.listen((_) => notifyListeners())];
  }

  late final List<StreamSubscription<Object?>> _subs;

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}

/// Bottom navigation that keeps each tab's state.
class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_view_week_outlined),
            selectedIcon: const Icon(Icons.calendar_view_week),
            label: l10n.navRoutine,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
