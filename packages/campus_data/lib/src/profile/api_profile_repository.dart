import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// [ProfileRepository] on top of the Campus Saga API.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile> updateProfile({
    required String displayName,
    required String department,
    required String batch,
  }) async {
    final data = await _api.patch('/me', {
      'displayName': displayName,
      'department': department,
      'batch': batch,
    });
    return UserProfile.fromJson(data! as Map<String, Object?>);
  }

  @override
  Future<List<String>> departmentSuggestions(String query) async {
    final q = Uri.encodeQueryComponent(query.trim());
    final data =
        (await _api.get('/me/department-suggestions?q=$q'))!
            as Map<String, Object?>;
    return (data['departments']! as List<Object?>).cast<String>();
  }
}
