import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// The phone, as sent with feedback.
class DeviceDetails {
  const DeviceDetails({
    required this.platform,
    required this.device,
    required this.os,
  });

  /// `android`, `ios`...
  final String platform;

  /// Brand and model, e.g. "samsung SM-A155F".
  final String device;

  /// e.g. "Android 14".
  final String os;
}

/// Reads the phone's model and system version.
abstract interface class DeviceDetailsSource {
  Future<DeviceDetails> read();
}

class PlatformDeviceDetails implements DeviceDetailsSource {
  @override
  Future<DeviceDetails> read() async {
    final platform = defaultTargetPlatform.name.toLowerCase();
    try {
      final plugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        return DeviceDetails(
          platform: platform,
          device: '${info.manufacturer} ${info.model}'.trim(),
          os: 'Android ${info.version.release}',
        );
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        return DeviceDetails(
          platform: platform,
          device: info.utsname.machine,
          os: 'iOS ${info.systemVersion}',
        );
      }
    } on Object {
      // Fall through: send what we know.
    }
    return DeviceDetails(platform: platform, device: '', os: '');
  }
}

/// For tests.
class MemoryDeviceDetails implements DeviceDetailsSource {
  MemoryDeviceDetails([
    this.details = const DeviceDetails(
      platform: 'android',
      device: 'Google Pixel 7',
      os: 'Android 14',
    ),
  ]);

  final DeviceDetails details;

  @override
  Future<DeviceDetails> read() async => details;
}
