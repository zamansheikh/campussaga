import 'package:geolocator/geolocator.dart';

/// Why there's no location.
enum LocationProblem { serviceOff, denied, deniedForever }

/// Where the phone is, for "Where am I" on bus maps. Asked only when the
/// student taps it, used on the phone and never sent anywhere.
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

  Future<void> openSettings(LocationProblem problem) =>
      problem == LocationProblem.serviceOff
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
