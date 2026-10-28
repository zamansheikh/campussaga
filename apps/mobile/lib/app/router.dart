import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/assessments/presentation/assessment_editor_page.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/email_sign_in_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/classes/presentation/pages/change_editor_page.dart';
import '../features/classes/presentation/pages/group_form_page.dart';
import '../features/classes/presentation/pages/group_page.dart';
import '../features/classes/presentation/pages/groups_page.dart';
import '../features/classes/presentation/pages/join_group_page.dart';
import '../features/classes/presentation/pages/members_page.dart';
import '../features/classes/presentation/pages/my_courses_page.dart';
import '../features/classes/presentation/pages/slot_editor_page.dart';
import '../features/explore/explore_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_setup_page.dart';
import '../features/profile/presentation/pages/verify_email_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/reminders/presentation/reminders_page.dart';
import '../features/routine/presentation/routine_page.dart';
import '../features/today/presentation/today_page.dart';
import '../features/transport/presentation/pages/bus_route_edit_page.dart';
import '../features/transport/presentation/pages/bus_route_page.dart';
import '../features/transport/presentation/pages/bus_routes_page.dart';
import '../features/transport/presentation/pages/bus_stops_edit_page.dart';
import '../features/transport/presentation/pages/bus_trips_edit_page.dart';
import '../features/voice/presentation/pages/anonymity_page.dart';
import '../features/voice/presentation/pages/campus_page.dart';
import '../features/voice/presentation/pages/issue_page.dart';
import '../features/voice/presentation/pages/my_issues_page.dart';
import '../features/voice/presentation/pages/raise_issue_page.dart';
import 'settings/bloc/settings_cubit.dart';
import 'version/version_gate_cubit.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signInEmail = '/sign-in/email';
  static const setupProfile = '/setup-profile';
  static const today = '/today';
  static const routine = '/routine';
  static const profile = '/profile';
  static const explore = '/explore';
  static const editProfile = '/profile/edit';
  static const reminders = '/profile/reminders';
  static const verifyEmail = '/profile/verify';
  static const groups = '/groups';
  static const joinGroup = '/groups/join';
  static const newGroup = '/groups/new';
  static const newPersonal = '/personal/new';
  static String editPersonal(String id) => '/personal/$id';
  static String groupCourses(String id) => '/groups/$id/courses';
  static String groupMembers(String id) => '/groups/$id/members';
  static String group(String id) => '/groups/$id';
  static String editGroup(String id) => '/groups/$id/edit';
  static String newSlot(String groupId) => '/groups/$groupId/class/new';
  static String editSlot(String groupId, String slotId) =>
      '/groups/$groupId/class/$slotId';

  /// Move one class on one date.
  static String changeClass(String groupId, String slotId, DateTime date) =>
      '/groups/$groupId/change?slot=$slotId&date=${formatDate(date)}';

  /// Add an extra class on one date.
  static String extraClass(String groupId, DateTime date) =>
      '/groups/$groupId/change?date=${formatDate(date)}';

  /// Add a test or deadline (optionally for a course on a date).
  static String newTest(String groupId, {String? course, DateTime? date}) =>
      Uri(
        path: '/groups/$groupId/test/new',
        queryParameters: {
          'course': ?course,
          if (date != null) 'date': formatDate(date),
        },
      ).toString();

  static String editTest(String groupId, String testId) =>
      '/groups/$groupId/test/$testId';

  /// Campus Voice (behind the campusVoice feature flag).
  static const campus = '/campus';
  static const campusNew = '/campus/new';
  static const campusMine = '/campus/mine';
  static const campusAnonymity = '/campus/anonymity';
  static String campusIssue(String id) => '/campus/issues/$id';

  // Bus routes (transport).
  static const bus = '/bus';
  static const busNew = '/bus/new';
  static String busRoute(String id) => '/bus/$id';
  static String busEdit(String id) => '/bus/$id/edit';
  static String busStops(String id) => '/bus/$id/stops';
  static String busTrips(String id) => '/bus/$id/trips';
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
      _busRoutes,
      GoRoute(
        path: '/personal/:slotId',
        builder: (context, state) {
          final id = state.pathParameters['slotId']!;
          return SlotEditorPage(
            groupId: personalGroupId,
            slotId: id == 'new' ? null : id,
          );
        },
      ),
      GoRoute(
        path: Routes.campusNew,
        builder: (context, state) => const RaiseIssuePage(),
      ),
      GoRoute(
        path: Routes.campusMine,
        builder: (context, state) => const MyIssuesPage(),
      ),
      GoRoute(
        path: Routes.campusAnonymity,
        builder: (context, state) => const AnonymityPage(),
      ),
      GoRoute(
        path: '/campus/issues/:id',
        builder: (context, state) =>
            IssuePage(issueId: state.pathParameters['id']!),
      ),
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
                path: 'courses',
                builder: (context, state) =>
                    MyCoursesPage(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'members',
                builder: (context, state) =>
                    MembersPage(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'change',
                builder: (context, state) => ChangeEditorPage(
                  groupId: state.pathParameters['id']!,
                  slotId: state.uri.queryParameters['slot'],
                  date: parseDate(state.uri.queryParameters['date']!),
                ),
              ),
              GoRoute(
                path: 'test/new',
                builder: (context, state) {
                  final q = state.uri.queryParameters;
                  return AssessmentEditorPage(
                    groupId: state.pathParameters['id']!,
                    courseCode: q['course'],
                    date: q['date'] == null ? null : parseDate(q['date']!),
                  );
                },
              ),
              GoRoute(
                path: 'test/:testId',
                builder: (context, state) => AssessmentEditorPage(
                  groupId: state.pathParameters['id']!,
                  assessmentId: state.pathParameters['testId'],
                ),
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
                path: Routes.campus,
                builder: (context, state) => const CampusPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explore,
                builder: (context, state) => const ExplorePage(),
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
                  GoRoute(
                    path: 'verify',
                    builder: (context, state) => const VerifyEmailPage(),
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

/// Bus routes: the list, one route, and the transport reps' editors.
final _busRoutes = GoRoute(
  path: Routes.bus,
  builder: (context, state) => const BusRoutesPage(),
  routes: [
    GoRoute(path: 'new', builder: (context, state) => const BusRouteEditPage()),
    GoRoute(
      path: ':routeId',
      builder: (context, state) =>
          BusRoutePage(routeId: state.pathParameters['routeId']!),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) =>
              BusRouteEditPage(routeId: state.pathParameters['routeId']),
        ),
        GoRoute(
          path: 'stops',
          builder: (context, state) =>
              BusStopsEditPage(routeId: state.pathParameters['routeId']!),
        ),
        GoRoute(
          path: 'trips',
          builder: (context, state) =>
              BusTripsEditPage(routeId: state.pathParameters['routeId']!),
        ),
      ],
    ),
  ],
);

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

/// Bottom navigation that keeps each tab's state: Today, Routine, Campus,
/// Explore, Profile. The Campus tab (branch [_campusBranch]) shows only
/// while the campusVoice flag is on.
class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  static const _campusBranch = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final voice = context.select(
      (VersionGateCubit g) => g.state.feature('campusVoice'),
    );
    // Visible tabs → branch indexes.
    final branches = [0, 1, if (voice) _campusBranch, 3, 4];
    final selected = branches.indexOf(shell.currentIndex);
    if (selected < 0) {
      // The flag went off while on the Campus tab: back to Today.
      WidgetsBinding.instance.addPostFrameCallback((_) => shell.goBranch(0));
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (i) {
          final branch = branches[i];
          shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(CsIcons.today),
            selectedIcon: const Icon(CsIcons.todayFill),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(CsIcons.routine),
            selectedIcon: const Icon(CsIcons.routineFill),
            label: l10n.navRoutine,
          ),
          if (voice)
            NavigationDestination(
              icon: const Icon(CsIcons.campus),
              selectedIcon: const Icon(CsIcons.campusFill),
              label: l10n.navCampus,
            ),
          NavigationDestination(
            icon: const Icon(CsIcons.explore),
            selectedIcon: const Icon(CsIcons.exploreFill),
            label: l10n.navExplore,
          ),
          NavigationDestination(
            icon: const Icon(CsIcons.profile),
            selectedIcon: const Icon(CsIcons.profileFill),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
