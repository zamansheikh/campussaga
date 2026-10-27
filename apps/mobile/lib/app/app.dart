import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/google_auth.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import 'di.dart';
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
  )..add(const AuthStarted());
  late final SettingsCubit _settings = SettingsCubit(getIt<SettingsStorage>());
  late final GoRouter _router = buildRouter(_auth, _settings);
  late final VersionGateCubit _versionGate = VersionGateCubit(
    config: getIt<AppConfigRepository>(),
    currentBuild: getIt<AppVersion>().build,
  )..check();

  // Re-check the minimum version when the app comes back to the foreground.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _versionGate.check,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
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
          builder: (context, child) =>
              BlocBuilder<VersionGateCubit, VersionGateState>(
                builder: (context, gate) =>
                    gate.status == VersionStatus.updateRequired
                    ? UpdateRequiredPage(storeUrl: gate.storeUrl)
                    : child ?? const SizedBox.shrink(),
              ),
        ),
      ),
    );
  }
}
