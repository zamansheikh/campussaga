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
import '../features/auth/presentation/pages/request_university_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/blood/presentation/pages/blood_page.dart';
import '../features/blood/presentation/pages/blood_request_form_page.dart';
import '../features/blood/presentation/pages/blood_request_page.dart';
import '../features/campus_admin/presentation/pages/campus_admin_page.dart';
import '../features/campus_admin/presentation/pages/sections_tab.dart';
import '../features/campus_admin/presentation/pages/students_tab.dart';
import '../features/cgpa/data/cgpa_store.dart';
import '../features/cgpa/presentation/cgpa_cubit.dart';
import '../features/cgpa/presentation/cgpa_page.dart';
import '../features/cgpa/presentation/scale_page.dart';
import '../features/cgpa/presentation/semester_page.dart';
import '../features/classes/data/invite_link.dart';
import '../features/classes/presentation/pages/change_editor_page.dart';
import '../features/classes/presentation/pages/class_preview_page.dart';
import '../features/classes/presentation/pages/course_info_page.dart';
import '../features/classes/presentation/pages/find_class_page.dart';
import '../features/classes/presentation/pages/group_form_page.dart';
import '../features/classes/presentation/pages/group_page.dart';
import '../features/classes/presentation/pages/groups_page.dart';
import '../features/classes/presentation/pages/join_group_page.dart';
import '../features/classes/presentation/pages/members_page.dart';
import '../features/classes/presentation/pages/my_courses_page.dart';
import '../features/classes/presentation/pages/slot_editor_page.dart';
import '../features/explore/explore_page.dart';
import '../features/feedback/presentation/pages/feedback_form_page.dart';
import '../features/feedback/presentation/pages/feedback_thread_page.dart';
import '../features/feedback/presentation/pages/help_feedback_page.dart';
import '../features/feedback/presentation/pages/my_feedback_page.dart';
import '../features/growth/data/referral_claim.dart';
import '../features/growth/presentation/pages/badges_page.dart';
import '../features/growth/presentation/pages/campaign_page.dart';
import '../features/growth/presentation/pages/student_profile_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_setup_page.dart';
import '../features/profile/presentation/pages/verify_email_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/reminders/presentation/reminders_page.dart';
import '../features/routine/presentation/routine_page.dart';
import '../features/sponsors/deals_page.dart';
import '../features/today/presentation/today_page.dart';
import '../features/transport/presentation/pages/bus_route_edit_page.dart';
import '../features/transport/presentation/pages/bus_route_map_page.dart';
import '../features/transport/presentation/pages/bus_route_page.dart';
import '../features/transport/presentation/pages/bus_routes_page.dart';
import '../features/transport/presentation/pages/bus_stops_edit_page.dart';
import '../features/transport/presentation/pages/bus_trips_edit_page.dart';
import '../features/verification/presentation/pages/get_verified_page.dart';
import '../features/verification/presentation/pages/vouch_page.dart';
import '../features/voice/presentation/pages/anonymity_page.dart';
import '../features/voice/presentation/pages/campus_page.dart';
import '../features/voice/presentation/pages/campus_visit_pages.dart';
import '../features/voice/presentation/pages/compose_page.dart';
import '../features/voice/presentation/pages/issue_page.dart';
import '../features/voice/presentation/pages/my_issues_page.dart';
import 'di.dart';
import 'settings/bloc/settings_cubit.dart';
import 'version/version_gate_cubit.dart';

/// A vouch code waiting for the student to sign in.
abstract final class PendingVouch {
  static String? code;
}

abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signInEmail = '/sign-in/email';

  /// "Request your university" (the email's domain isn't recognized).
  static const requestUniversity = '/sign-in/university';
  static String requestUniversityFor(String email) => Uri(
    path: requestUniversity,
    queryParameters: {'email': email},
  ).toString();
  static const setupProfile = '/setup-profile';
  static const today = '/today';
  static const routine = '/routine';
  static const profile = '/profile';

  /// The profile, scrolled to its invite card (`invites`) or badges
  /// (`badges`).
  static String profileSection(String section) => '/profile?show=$section';

  /// Another student's profile.
  static String student(String id) => '/u/${Uri.encodeComponent(id)}';

  /// A prize campaign.
  static String campaign(String id) => '/campaigns/${Uri.encodeComponent(id)}';
  static const explore = '/explore';

  /// CGPA calculator (on the phone only).
  static const cgpa = '/cgpa';
  static const cgpaScale = '/cgpa/scale';
  static String cgpaSemester(String id) => '/cgpa/semester/$id';
  static const editProfile = '/profile/edit';
  static const reminders = '/profile/reminders';
  static const verifyEmail = '/profile/verify';

  /// Get verified: email, CR or classmates.
  static const verify = '/verify';

  /// A classmate's vouch link (https://varsitykotha.com/v/{code}).
  static String vouch(String code) => '/v/$code';

  /// Campus admin tools; [tab] is inbox, students, sections, bus,
  /// reports or blood.
  static const campusAdmin = '/campus-admin';
  static String campusAdminTab(String tab) => '/campus-admin/$tab';
  static String campusStudent(String id) => '/campus-admin/students/$id';
  static String campusSection(String id) => '/campus-admin/sections/$id';

  /// Every badge, earned and still to earn.
  static const badges = '/profile/badges';

  /// Help & feedback.
  static const help = '/profile/help';
  static const feedbackSend = '/profile/help/send';
  static const feedbackMine = '/profile/help/mine';
  static String feedbackThread(String id) => '/profile/help/mine/$id';
  static const groups = '/groups';
  static const joinGroup = '/groups/join';
  static String joinWith(String code) => '$joinGroup?code=$code';
  static String invite(String code) => '/join/$code';
  static const newGroup = '/groups/new';
  static const newPersonal = '/personal/new';
  static String editPersonal(String id) => '/personal/$id';
  static String groupCourses(String id) => '/groups/$id/courses';

  /// A course's links (chat group, Classroom code…): the CR edits them.
  static String courseInfo(String groupId, String courseCode) =>
      '/groups/$groupId/courses/${Uri.encodeComponent(courseCode)}';
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

  /// Visit other campuses: the list, and one university (by slug).
  static const campusVisit = '/campus/visit';
  static String campusOf(String slug) => '/campus/u/$slug';

  /// A post; [comment] opens it with the comment box ready.
  static String campusIssue(String id, {bool comment = false}) =>
      '/campus/issues/$id${comment ? '?comment=1' : ''}';

  /// The composer, on a kind; [photo] starts by picking a photo.
  static String campusCompose(PostKind kind, {bool photo = false}) =>
      '$campusNew?kind=${kind.wire}${photo ? '&photo=1' : ''}';

  /// A shared post link (https://varsitykotha.com/c/{id}).
  static String postLink(String id) => '/c/$id';

  // Find your class (routine discovery).
  static const findClass = '/find-class';
  static String classPreview(String groupId, {String? code}) => Uri(
    path: '/find-class/$groupId',
    queryParameters: code == null ? null : {'code': code},
  ).toString();
  // Bus routes (transport).
  static const bus = '/bus';

  /// Blood donation: requests and the donor profile.
  static const blood = '/blood';

  /// Student deals (sponsored offers).
  static const deals = '/deals';
  static const bloodNew = '/blood/new';
  static String bloodRequest(String id) => '/blood/requests/$id';
  static const busNew = '/bus/new';
  static String busRoute(String id) => '/bus/$id';
  static String busEdit(String id) => '/bus/$id/edit';
  static String busStops(String id) => '/bus/$id/stops';
  static String busTrips(String id) => '/bus/$id/trips';
  static String busMap(String id) => '/bus/$id/map';

  /// `extra` for [busRoute] right after creating it: start the setup.
  static const busSetup = 'setup';
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
      // An invite link (https://varsitykotha.com/join/ABCDEF): keep the
      // code until the student is signed in and set up, then join.
      if (at.startsWith('/join/')) {
        final code = InviteLink.code(state.pathParameters['code']);
        if (code != null) PendingInvite.save(code);
        // A class invite shared with the sharer's own code: that friend
        // brought this student.
        final ref = state.uri.queryParameters['ref'];
        if (ref != null) PendingReferral.save(ref, source: 'join');
        if (status == AuthStatus.signedIn && !auth.state.needsProfileSetup) {
          unawaited(claimPendingReferral());
          final c = PendingInvite.take();
          return c == null ? Routes.today : Routes.joinWith(c);
        }
        // Otherwise on as usual (welcome, sign-in, profile setup); the code
        // waits and is used right after.
      }
      // A personal invite link (https://varsitykotha.com/r/{code}): keep the
      // code, to claim after sign-in; then on to Today.
      if (at.startsWith('/r/')) {
        final code = InviteLink.referralCode(state.pathParameters['code']);
        if (code != null) PendingReferral.save(code, source: 'link');
        if (status == AuthStatus.signedIn && !auth.state.needsProfileSetup) {
          unawaited(claimPendingReferral());
          return Routes.today;
        }
      }
      // A vouch link (https://varsitykotha.com/v/xxxxxxxx): keep the code
      // until the student is signed in and set up.
      if (at.startsWith('/v/')) {
        final code = state.pathParameters['code'];
        if (code != null) PendingVouch.code = code;
        if (status == AuthStatus.signedIn && !auth.state.needsProfileSetup) {
          PendingVouch.code = null;
          return null;
        }
      }
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
        final v = PendingVouch.code;
        if (v != null) {
          PendingVouch.code = null;
          return Routes.vouch(v);
        }
        final c = PendingInvite.take();
        return c == null ? Routes.today : Routes.joinWith(c);
      }
      return null;
    },
    routes: [
      // Invite links; the redirect above sends them on (this never shows).
      GoRoute(
        path: '/join/:code',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/r/:code',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/u/:id',
        builder: (context, state) =>
            StudentProfilePage(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/campaigns/:id',
        builder: (context, state) =>
            CampaignPage(campaignId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/v/:code',
        builder: (context, state) =>
            VouchPage(code: state.pathParameters['code']!),
      ),
      GoRoute(
        path: Routes.verify,
        builder: (context, state) => const GetVerifiedPage(),
      ),
      GoRoute(
        path: Routes.campusAdmin,
        redirect: (context, state) => state.uri.path == Routes.campusAdmin
            ? Routes.campusAdminTab('inbox')
            : null,
        routes: [
          GoRoute(
            path: 'students/:id',
            builder: (context, state) =>
                CampusStudentPage(studentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'sections/:id',
            builder: (context, state) =>
                SectionPage(sectionId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: ':tab',
            builder: (context, state) =>
                CampusAdminPage(tab: state.pathParameters['tab']!),
          ),
        ],
      ),
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
          GoRoute(
            path: 'university',
            builder: (context, state) => RequestUniversityPage(
              email: state.uri.queryParameters['email'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.setupProfile,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      // Full-screen pages over the tabs.
      _busRoutes,
      _bloodRoutes,
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
      // CGPA calculator: one record shared by its pages.
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (context) => CgpaCubit(
            getIt.isRegistered<CgpaStore>()
                ? getIt<CgpaStore>()
                : PrefsCgpaStore(),
            context.read<AuthBloc>().state.user?.id ?? '',
          )..load(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.cgpa,
            builder: (context, state) => const CgpaPage(),
            routes: [
              GoRoute(
                path: 'scale',
                builder: (context, state) => const ScalePage(),
              ),
              GoRoute(
                path: 'semester/:id',
                builder: (context, state) =>
                    SemesterPage(semesterId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.campusNew,
        builder: (context, state) => ComposePage(
          kind: PostKind.parse(state.uri.queryParameters['kind'] ?? 'post'),
          pickPhoto: state.uri.queryParameters['photo'] == '1',
        ),
      ),
      // A shared post (https://varsitykotha.com/c/{id}): open it.
      GoRoute(
        path: '/c/:id',
        redirect: (context, state) =>
            Routes.campusIssue(state.pathParameters['id']!),
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
        path: Routes.campusVisit,
        builder: (context, state) => const VisitCampusesPage(),
      ),
      GoRoute(
        path: '/campus/u/:slug',
        builder: (context, state) =>
            CampusVisitPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/campus/issues/:id',
        builder: (context, state) => IssuePage(
          issueId: state.pathParameters['id']!,
          focusComment: state.uri.queryParameters['comment'] == '1',
        ),
      ),
      GoRoute(
        path: Routes.deals,
        builder: (context, state) => const DealsPage(),
      ),
      // Find your class: search, then a group's routine preview.
      GoRoute(
        path: Routes.findClass,
        builder: (context, state) => const FindClassPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => ClassPreviewPage(
              groupId: state.pathParameters['id']!,
              code: state.uri.queryParameters['code'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.groups,
        builder: (context, state) => const GroupsPage(),
        routes: [
          GoRoute(
            path: 'join',
            builder: (context, state) =>
                JoinGroupPage(code: state.uri.queryParameters['code']),
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
                routes: [
                  GoRoute(
                    path: ':code',
                    builder: (context, state) => CourseInfoPage(
                      groupId: state.pathParameters['id']!,
                      courseCode: state.pathParameters['code']!,
                    ),
                  ),
                ],
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
                builder: (context, state) =>
                    ProfilePage(show: state.uri.queryParameters['show']),
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
                  GoRoute(
                    path: 'badges',
                    builder: (context, state) => const BadgesPage(),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => const HelpFeedbackPage(),
                    routes: [
                      GoRoute(
                        path: 'send',
                        builder: (context, state) => const FeedbackFormPage(),
                      ),
                      GoRoute(
                        path: 'mine',
                        builder: (context, state) => const MyFeedbackPage(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (context, state) => FeedbackThreadPage(
                              feedbackId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Blood donation: the page, a new request, one request; a shared link
/// (https://varsitykotha.com/blood/{id}) opens the request.
final _bloodRoutes = GoRoute(
  path: Routes.blood,
  builder: (context, state) => const BloodPage(),
  routes: [
    GoRoute(
      path: 'new',
      builder: (context, state) => const BloodRequestFormPage(),
    ),
    GoRoute(
      path: 'requests/:id',
      builder: (context, state) =>
          BloodRequestPage(requestId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: ':id',
      redirect: (context, state) =>
          Routes.bloodRequest(state.pathParameters['id']!),
    ),
  ],
);

/// Bus routes: the list, one route, and the transport reps' editors.
final _busRoutes = GoRoute(
  path: Routes.bus,
  builder: (context, state) => const BusRoutesPage(),
  routes: [
    GoRoute(path: 'new', builder: (context, state) => const BusRouteEditPage()),
    GoRoute(
      path: ':routeId',
      builder: (context, state) => BusRoutePage(
        routeId: state.pathParameters['routeId']!,
        setup: state.extra == Routes.busSetup,
      ),
      routes: [
        GoRoute(
          path: 'map',
          builder: (context, state) =>
              BusRouteMapPage(routeId: state.pathParameters['routeId']!),
        ),
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
