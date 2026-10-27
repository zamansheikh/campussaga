/// This phone's push notification registration. Throws a `Failure`.
abstract interface class DeviceRepository {
  /// Registers (or updates) this phone for the signed-in student.
  /// [platform] is 'android' or 'ios'; [language] 'en' or 'bn'.
  Future<void> registerDevice({
    required String token,
    required String platform,
    required String language,
  });
}
