import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

class ApiAppConfigRepository implements AppConfigRepository {
  ApiAppConfigRepository(this._api);

  final ApiClient _api;

  @override
  Future<AppConfig> fetch() async {
    final data = await _api.send('GET', '/config', authenticated: false);
    return AppConfig.fromJson(data! as Map<String, Object?>);
  }
}
