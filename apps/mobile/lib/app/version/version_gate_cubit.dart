import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum VersionStatus { ok, updateRequired }

final class VersionGateState extends Equatable {
  const VersionGateState({
    this.status = VersionStatus.ok,
    this.storeUrl,
    this.features = const {},
  });

  final VersionStatus status;

  /// Store page for this platform, when the server has one.
  final String? storeUrl;

  /// Server feature flags from the same /config call (e.g. campusVoice).
  final Map<String, bool> features;

  bool feature(String name) => features[name] ?? false;

  @override
  List<Object?> get props => [
    status,
    storeUrl,
    for (final e
        in (features.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
      '${e.key}=${e.value}',
  ];
}

/// Blocks the app when this build is older than the server's
/// minSupportedBuild, and carries the server's feature flags. Fails open: if the server can't be reached the
/// student keeps using the app.
class VersionGateCubit extends Cubit<VersionGateState> {
  VersionGateCubit({
    required AppConfigRepository config,
    required int currentBuild,
    String? platform,
    DateTime Function()? now,
  }) : _appConfig = config,
       _build = currentBuild,
       _platform =
           platform ??
           (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
       _now = now ?? DateTime.now,
       super(const VersionGateState());

  final AppConfigRepository _appConfig;
  final int _build;
  final String _platform;
  final DateTime Function() _now;
  DateTime? _lastCheck;

  static const recheckAfter = Duration(minutes: 10);

  /// At start and when the app comes back to the foreground.
  Future<void> check() async {
    final now = _now();
    if (_lastCheck != null && now.difference(_lastCheck!) < recheckAfter) {
      return;
    }
    _lastCheck = now;
    try {
      final cfg = await _appConfig.fetch();
      final next = cfg.isSupported(_build)
          ? VersionGateState(features: cfg.features)
          : VersionGateState(
              status: VersionStatus.updateRequired,
              storeUrl: cfg.storeUrls[_platform],
              features: cfg.features,
            );
      if (next != state) emit(next); // nothing to rebuild when unchanged
    } on Failure {
      _lastCheck = null; // offline: try again next time, keep current state
    }
  }
}
