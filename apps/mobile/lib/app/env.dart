/// Build-time configuration.
///
/// Values come from `--dart-define-from-file=env/<name>.json`
/// (copy env/example.json to env/local.json). Env files with real values
/// are git-ignored. Only public values belong here: never a secret key.
abstract final class Env {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isProduction => appEnv == 'production';
}
