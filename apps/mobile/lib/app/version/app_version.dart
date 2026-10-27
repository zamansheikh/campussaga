/// This build's version, read once at start (package_info_plus).
class AppVersion {
  const AppVersion({required this.version, required this.build});

  /// e.g. "0.1.0"
  final String version;

  /// The build number compared with the server's minSupportedBuild.
  final int build;
}
