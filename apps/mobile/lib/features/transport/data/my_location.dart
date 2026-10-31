import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:geolocator/geolocator.dart';

/// Why there's no location.
enum LocationProblem { serviceOff, denied, deniedForever }

/// Where the phone is: for "Where am I" on bus maps (used on the phone
/// only), and while the student shares a bus live ([sharing]; those
/// points go to the server, see docs/BUS_LIVE.md).
class MyLocation {
  const MyLocation();

  /// Tests replace this.
  static MyLocation instance = const MyLocation();

  /// Asks for permission when needed, then returns the current position or
  /// what's in the way.
  Future<({Position? position, LocationProblem? problem})> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (position: null, problem: LocationProblem.serviceOff);
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      return (position: null, problem: LocationProblem.deniedForever);
    }
    if (p == LocationPermission.denied ||
        p == LocationPermission.unableToDetermine) {
      return (position: null, problem: LocationProblem.denied);
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (position: pos, problem: null);
    } on Exception {
      final last = await Geolocator.getLastKnownPosition();
      return (
        position: last,
        problem: last == null ? LocationProblem.serviceOff : null,
      );
    }
  }

  /// Updates while the map is open (after [current] was allowed).
  Stream<Position> updates() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    ),
  );

  /// Updates while the student shares a bus live: they keep coming with
  /// the screen off, under an ongoing notification (Android's foreground
  /// service; started while the app is open, so no background permission).
  Stream<Position> sharing({
    required String title,
    required String text,
    required String channel,
  }) => Geolocator.getPositionStream(
    locationSettings: defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            distanceFilter: 20,
            intervalDuration: const Duration(seconds: 10),
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: title,
              notificationText: text,
              notificationChannelName: channel,
              notificationIcon: const AndroidResource(name: 'ic_notification'),
              setOngoing: true,
              enableWakeLock: true,
              color: const Color(0xFF0F766E),
            ),
          )
        : defaultTargetPlatform == TargetPlatform.iOS
        ? AppleSettings(
            distanceFilter: 20,
            activityType: ActivityType.automotiveNavigation,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
            allowBackgroundLocationUpdates: true,
          )
        : const LocationSettings(distanceFilter: 20),
  );

  Future<void> openSettings(LocationProblem problem) =>
      problem == LocationProblem.serviceOff
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
