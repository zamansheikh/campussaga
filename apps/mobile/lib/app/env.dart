import 'package:flutter/foundation.dart';

/// Build-time configuration.
///
/// Values come from `--dart-define-from-file=env/<name>.json`
/// (copy env/example.json to env/local.json). Env files with real values
/// are git-ignored. Only public values belong here: never a secret.
abstract final class Env {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Local backend used by debug builds started without an env file
  /// (editor "Run" button, plain `flutter run`). Works on the iOS simulator,
  /// and on Android with `adb reverse tcp:8090 tcp:8090`.
  static const String localApiBaseUrl = 'http://localhost:8090/api/v1';

  /// VarsityKotha API, including the /api/v1 prefix. Release builds must set
  /// API_BASE_URL; they never fall back to localhost.
  static String get apiBaseUrl => _apiBaseUrl.isNotEmpty
      ? _apiBaseUrl
      : (kReleaseMode ? '' : localApiBaseUrl);

  /// Public web pages (apps/web; GitHub Pages keeps a copy). The old
  /// campus.silifton.com redirects here.
  static const String siteUrl = 'https://varsitykotha.com';
  static const String privacyPolicyUrl = '$siteUrl/privacy.html';

  /// Where testers and students send feedback.
  static const String supportEmail = 'hello@silifton.com';

  static bool get isProduction => appEnv == 'production';
}
