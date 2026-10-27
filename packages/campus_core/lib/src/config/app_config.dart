/// Public settings from the server (GET /config).
class AppConfig {
  const AppConfig({
    required this.minSupportedBuild,
    this.storeUrls = const {},
    this.features = const {},
  });

  factory AppConfig.fromJson(Map<String, Object?> json) => AppConfig(
    minSupportedBuild: (json['minSupportedBuild'] as num?)?.toInt() ?? 0,
    storeUrls: {
      for (final e
          in ((json['storeUrls'] as Map?) ?? const <String, Object?>{}).entries)
        if (e.value is String) e.key.toString(): e.value! as String,
    },
    features: {
      for (final e
          in ((json['features'] as Map?) ?? const <String, Object?>{}).entries)
        if (e.value is bool) e.key.toString(): e.value! as bool,
    },
  );

  /// Builds below this must update before using the app.
  final int minSupportedBuild;

  /// Store page per platform ('android', 'ios'), when published.
  final Map<String, String> storeUrls;

  /// Feature flags, e.g. {'myClass': true}.
  final Map<String, bool> features;

  bool isSupported(int build) => build >= minSupportedBuild;
}

/// Reads [AppConfig]. Throws a `Failure` when the server can't be reached.
abstract interface class AppConfigRepository {
  Future<AppConfig> fetch();
}
