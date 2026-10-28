import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// [DeviceRepository] on top of the VarsityKotha API.
class ApiDeviceRepository implements DeviceRepository {
  ApiDeviceRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
    required String language,
  }) => _api.post('/me/devices', {
    'token': token,
    'platform': platform,
    'language': language,
  });
}
