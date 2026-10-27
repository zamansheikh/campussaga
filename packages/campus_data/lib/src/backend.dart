import 'package:supabase_flutter/supabase_flutter.dart';

/// Connection settings for the backend, passed in from the app's env file.
class BackendConfig {
  const BackendConfig({required this.url, required this.publishableKey});

  /// e.g. https://api.example.com (our self-hosted Supabase).
  final String url;

  /// Public key (the "anon" / publishable key). Safe to ship in the app;
  /// access is enforced by Row Level Security on the server.
  /// Never put the service role / secret key here.
  final String publishableKey;

  bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

/// Starts the backend client. Call once at app start, before using any
/// repository from this package.
abstract final class Backend {
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> init(BackendConfig config) async {
    if (_ready || !config.isConfigured) return;
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    _ready = true;
  }
}
