import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// What the reminders screen needs to know about the phone.
abstract interface class PhoneInfo {
  /// The brand, if it is known to stop apps in the background (so
  /// reminders can arrive late); null otherwise.
  Future<String?> strictBatteryBrand();

  /// Opens the phone's battery settings for this app.
  Future<void> openBatterySettings();
}

class DevicePhoneInfo implements PhoneInfo {
  // Brands whose battery savers often kill background apps
  // (see dontkillmyapp.com). Lower case, as Android reports them.
  static const _strict = {
    'xiaomi': 'Xiaomi',
    'redmi': 'Redmi',
    'poco': 'POCO',
    'oppo': 'OPPO',
    'realme': 'realme',
    'vivo': 'vivo',
    'iqoo': 'iQOO',
    'oneplus': 'OnePlus',
    'samsung': 'Samsung',
    'huawei': 'Huawei',
    'honor': 'HONOR',
    'infinix': 'Infinix',
    'tecno': 'TECNO',
    'itel': 'itel',
  };

  String? _brand;
  bool _read = false;

  @override
  Future<String?> strictBatteryBrand() async {
    if (_read) return _brand;
    _read = true;
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return _brand =
          _strict[info.manufacturer.toLowerCase()] ??
          _strict[info.brand.toLowerCase()];
    } on Object {
      return null;
    }
  }

  @override
  Future<void> openBatterySettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
}

/// For tests.
class MemoryPhoneInfo implements PhoneInfo {
  MemoryPhoneInfo([this.brand]);

  String? brand;
  int opened = 0;

  @override
  Future<String?> strictBatteryBrand() async => brand;

  @override
  Future<void> openBatterySettings() async => opened++;
}
