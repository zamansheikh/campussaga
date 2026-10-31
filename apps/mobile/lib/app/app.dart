import 'dart:async';
import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/announcements/data/seen_store.dart';
import '../features/announcements/presentation/seen_cubit.dart';
import '../features/auth/data/google_auth.dart';
import '../features/auth/data/profile_cache.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/classes/data/routine_cache.dart';
import '../features/classes/presentation/bloc/my_classes_cubit.dart';
import '../features/growth/data/referral_claim.dart';
import '../features/push/push_controller.dart';
import '../features/push/push_messaging.dart';
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/reminders/data/reminder_store.dart';
import '../features/reminders/presentation/bloc/reminders_cubit.dart';
import '../features/transport/data/bus_sharing.dart';
import '../features/voice/data/voice_cache.dart';
import '../features/voice/presentation/widgets/voice_image.dart';
import '../features/widget/home_widget.dart';
import 'di.dart';
import 'open_link.dart';
import 'router.dart';
import 'settings/bloc/settings_cubit.dart';
import 'settings/bloc/settings_state.dart';
import 'settings/settings_storage.dart';
import 'version/app_version.dart';
import 'version/update_required_page.dart';
import 'version/version_gate_cubit.dart';

class CampusApp extends StatefulWidget {
  const CampusApp({super.key});

  @override
  State<CampusApp> createState() => _CampusAppState();
}

class _CampusAppState extends State<CampusApp> {
  late final AuthBloc _auth = AuthBloc(
    repository: getIt<AuthRepository>(),
    google: getIt<GoogleAuth>(),
    profileCache: getIt<ProfileCache>(),
  )..add(const AuthStarted());
  late final MyClassesCubit _classes = MyClassesCubit(
    getIt<ClassGroupRepository>(),
    getIt<RoutineCache>(),
  );
  late final StreamSubscription<AuthState> _authSub;
  late final RemindersCubit _reminders = RemindersCubit(
    getIt<ReminderStore>(),
    getIt<ReminderScheduler>(),
  );
  late final StreamSubscription<List<ClassGroup>> _classesSub;
  late final StreamSubscription<String> _tapSub;
  late final SeenCubit _seen = SeenCubit(getIt<SeenStore>());
  late final PushController _push = PushController(
    getIt<PushMessaging>(),
    getIt<DeviceRepository>(),
    onForeground: _onPush,
    onOpened: _onPushOpened,
  );
  String? _pushUser;
  // Android home-screen widget: next class and next test.
  late final HomeWidgetSync _homeWidget = HomeWidgetSync();
  late final SettingsCubit _settings = SettingsCubit(getIt<SettingsStorage>());
  late final GoRouter _router = buildRouter(_auth, _settings);
  late final VersionGateCubit _versionGate = VersionGateCubit(
    config: getIt<AppConfigRepository>(),
    currentBuild: getIt<AppVersion>().build,
  )..check();

  // Back in the foreground: re-check the minimum version, fetch the latest
  // routine.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () {
      _auth.add(const AuthRefreshRequested());
      _versionGate.check();
      unawaited(_classes.refresh());
      unawaited(_reminders.refresh());
    },
  );

  @override
  void initState() {
    super.initState();
    CsLinkText.onOpen = linkOpener(_router);
    _lifecycle; // start listening
    _onAuth(_auth.state);
    _authSub = _auth.stream.listen(_onAuth);
    // Reminders follow the routine, personal classes included (cleared
    // with it on sign-out).
    unawaited(_reminders.start());
    unawaited(_seen.start());
    _push.start();
    _tapSub = getIt<ReminderScheduler>().taps.listen(_onNotificationTap);
    _homeWidget.attach(classes: _classes, auth: _auth, settings: _settings);
    _classesSub = _classes.stream
        .map((s) => s.routine)
        .distinct()
        .listen((g) => unawaited(_reminders.updateGroups(g)));
  }

  /// The routine and pushes follow the signed-in student.
  void _onAuth(AuthState s) {
    final id = s.user?.id;
    if (s.status == AuthStatus.signedIn && id != null) {
      unawaited(_classes.start(id));
      // Whose invite brought this student (a link, or installing through
      // one): told to the server once.
      unawaited(claimPendingReferral());
      if (_pushUser != id) {
        _pushUser = id;
        unawaited(_push.signedIn());
      }
      // Pushes are only shown with permission (Android 13+): ask once the
      // student is past sign-in and profile setup.
      if (!s.needsProfileSetup) unawaited(_push.askPermission());
    } else if (s.status == AuthStatus.signedOut) {
      unawaited(_classes.clear());
      // No more sharing a bus as the account that left.
      if (getIt.isRegistered<BusSharing>()) {
        unawaited(getIt<BusSharing>().stop());
      }
      // Campus Voice: nothing of this account stays on the phone.
      unawaited(getIt<VoiceCache>().clear());
      VoiceImage.clear();
      _pushUser = null;
      _push.signedOut();
    }
  }

  /// Pushes about invites, badges and prizes (nothing to refresh for them).
  static const _growthPushes = {
    'referral_joined',
    'badge_earned',
    'campaign_won',
    'race_finished',
  };

  /// A push while the app is open: show it, and fetch what changed.
  void _onPush(PushNote note) {
    final type = '${note.data['type']}';
    if (!type.startsWith('issue_') &&
        !type.startsWith('feedback_') &&
        type != 'campus_verified' &&
        !type.startsWith('blood_') &&
        !type.startsWith('bus_') &&
        !_growthPushes.contains(type)) {
      unawaited(_classes.refresh());
    }
    // Verified by a CR, classmates or a campus admin: the "Get verified"
    // banners go away at once.
    if (type == 'campus_verified') unawaited(_reloadProfile());
    final title = note.title;
    if (title == null) return;
    unawaited(
      getIt<ReminderScheduler>().showUpdate(
        title: title,
        body: note.body ?? '',
        // Tapping it then does what tapping the push itself does.
        payload: jsonEncode({'push': note.data}),
      ),
    );
  }

  /// Fetches the profile again (e.g. just verified by people).
  Future<void> _reloadProfile() async {
    if (_auth.state.status != AuthStatus.signedIn) return;
    try {
      final user = await getIt<AuthRepository>().restoreSession();
      if (user != null && mounted) _auth.add(AuthProfileUpdated(user));
    } on Failure {
      // Offline: the next start shows it.
    }
  }

  /// A notification shown while the app was open was tapped. Class
  /// reminders carry a plain group id and keep just opening the app.
  void _onNotificationTap(String payload) {
    if (!payload.startsWith('{')) return;
    try {
      final data = (jsonDecode(payload) as Map)['push'];
      if (data is Map) {
        _onPushOpened(PushNote(data: data.cast<String, Object?>()));
      }
    } on FormatException {
      // Not one of ours.
    }
  }

  /// A push was tapped: open its issue (Campus Voice) or, after fetching
  /// what changed, its group.
  void _onPushOpened(PushNote note) {
    final route = note.data['routeId'];
    if ('${note.data['type']}'.startsWith('bus_') && route is String) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (_auth.state.status == AuthStatus.signedIn) {
            unawaited(_router.push(Routes.busRoute(route)));
          }
        })
        ..ensureVisualUpdate();
      return;
    }
    final type = '${note.data['type']}';
    if (type == 'campus_verified') {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (_auth.state.status == AuthStatus.signedIn) {
            unawaited(_reloadProfile());
            _router.go(Routes.profile);
          }
        })
        ..ensureVisualUpdate();
      return;
    }
    if (_growthPushes.contains(type)) {
      final campaign = note.data['campaignId'];
      final route = switch (type) {
        'referral_joined' => Routes.profileSection('invites'),
        'badge_earned' => Routes.profileSection('badges'),
        _ when campaign is String => Routes.campaign(campaign),
        _ => Routes.profile,
      };
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (_auth.state.status == AuthStatus.signedIn) {
            if ((type == 'campaign_won' || type == 'race_finished') &&
                campaign is String) {
              unawaited(_router.push(route));
            } else {
              _router.go(route);
            }
          }
        })
        ..ensureVisualUpdate();
      return;
    }
    final feedback = note.data['feedbackId'];
    if (type == 'feedback_reply' && feedback is String) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (_auth.state.status == AuthStatus.signedIn) {
            unawaited(_router.push(Routes.feedbackThread(feedback)));
          }
        })
        ..ensureVisualUpdate();
      return;
    }
    final blood = note.data['requestId'];
    if ('${note.data['type']}'.startsWith('blood_') && blood is String) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (_auth.state.status == AuthStatus.signedIn) {
            unawaited(_router.push(Routes.bloodRequest(blood)));
          }
        })
        ..ensureVisualUpdate();
      return;
    }
    final issue = note.data['issueId'];
    if ('${note.data['type']}'.startsWith('issue_') && issue is String) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (_auth.state.status == AuthStatus.signedIn) {
            unawaited(_router.push(Routes.campusIssue(issue)));
          }
        })
        ..ensureVisualUpdate(); // nothing else may be drawing right now
      return;
    }
    unawaited(_classes.refresh());
    final group = note.groupId;
    if (group == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.state.status == AuthStatus.signedIn) {
        unawaited(_router.push(Routes.group(group)));
      }
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_authSub.cancel());
    unawaited(_classesSub.cancel());
    unawaited(_tapSub.cancel());
    _push.dispose();
    _homeWidget.dispose();
    _reminders.close();
    _seen.close();
    _classes.close();
    _router.dispose();
    _auth.close();
    _settings.close();
    _versionGate.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _auth),
        BlocProvider.value(value: _versionGate),
        BlocProvider.value(value: _settings),
        BlocProvider.value(value: _classes),
        BlocProvider.value(value: _reminders),
        BlocProvider.value(value: _seen),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: CsTheme.light,
          darkTheme: CsTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
          // An unsupported build sees only the update screen.
          builder: (context, child) => _ReminderLanguage(
            reminders: _reminders,
            push: _push,
            child: BlocBuilder<VersionGateCubit, VersionGateState>(
              builder: (context, gate) =>
                  gate.status == VersionStatus.updateRequired
                  ? UpdateRequiredPage(storeUrl: gate.storeUrl)
                  : child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tells reminders and pushes the app's language, so notifications use it.
class _ReminderLanguage extends StatefulWidget {
  const _ReminderLanguage({
    required this.reminders,
    required this.push,
    required this.child,
  });

  final RemindersCubit reminders;
  final PushController push;
  final Widget child;

  @override
  State<_ReminderLanguage> createState() => _ReminderLanguageState();
}

class _ReminderLanguageState extends State<_ReminderLanguage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    unawaited(widget.reminders.setLocale(locale));
    unawaited(widget.push.setLanguage(locale.languageCode));
    final l10n = AppLocalizations.of(context);
    unawaited(
      getIt<ReminderScheduler>().prepareUpdatesChannel(
        name: l10n.pushChannel,
        description: l10n.pushChannelHint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
