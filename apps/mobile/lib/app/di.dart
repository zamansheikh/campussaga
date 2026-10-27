import 'package:campus_core/campus_core.dart';
import 'package:campus_data/campus_data.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features/announcements/data/seen_store.dart';
import '../features/auth/data/google_auth.dart';
import '../features/classes/data/routine_cache.dart';
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/reminders/data/reminder_store.dart';
import 'crash/crash_reporter.dart';
import 'env.dart';
import 'settings/settings_storage.dart';
import 'version/app_version.dart';

/// Service locator for long-lived services (API client, repositories).
/// Blocs are not registered here: they are created where a screen needs
/// them, and get their repositories from [getIt].
final getIt = GetIt.instance;

/// Registers every service. Call once in main(), after Firebase starts and
/// before runApp: saved settings and the app version are read here so the
/// first frame is already right. Tests register fakes instead.
Future<void> configureDependencies({
  required CrashReporter crashReporter,
}) async {
  if (getIt.isRegistered<ApiClient>()) return;
  final settings = await PrefsSettingsStorage.open();
  final info = await PackageInfo.fromPlatform();
  getIt
    ..registerSingleton<CrashReporter>(crashReporter)
    ..registerSingleton<SettingsStorage>(settings)
    ..registerSingleton<AppVersion>(
      AppVersion(
        version: info.version,
        build: int.tryParse(info.buildNumber) ?? 0,
      ),
    )
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(ApiConfig(baseUrl: Env.apiBaseUrl)),
      dispose: (client) => client.close(),
    )
    ..registerLazySingleton<TokenStore>(SecureTokenStore.new)
    ..registerLazySingleton<AuthRepository>(
      () => ApiAuthRepository(getIt<ApiClient>(), getIt<TokenStore>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ApiProfileRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<AppConfigRepository>(
      () => ApiAppConfigRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ClassGroupRepository>(
      () => ApiClassGroupRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<RoutineCache>(PrefsRoutineCache.new)
    ..registerLazySingleton<ReminderStore>(PrefsReminderStore.new)
    ..registerLazySingleton<SeenStore>(PrefsSeenStore.new)
    ..registerLazySingleton<ReminderScheduler>(LocalNotificationScheduler.new)
    ..registerLazySingleton<GoogleAuth>(FirebaseGoogleAuth.new);
}
