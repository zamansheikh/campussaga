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

  /// Campus Saga API, including the /api/v1 prefix.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isProduction => appEnv == 'production';
}
