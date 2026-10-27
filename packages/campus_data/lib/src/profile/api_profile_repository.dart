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

  @override
  Future<List<University>> universities() async {
    final data = (await _api.get('/universities'))! as Map<String, Object?>;
    return [
      for (final u in data['universities']! as List<Object?>)
        University.fromJson(u! as Map<String, Object?>),
    ];
  }

  @override
  Future<UserProfile> setUniversity(
    String universityId, {
    bool leaveVerified = false,
  }) async => UserProfile.fromJson(
    (await _api.put('/me/university', {
          'universityId': universityId,
          'leaveVerified': leaveVerified,
        }))!
        as Map<String, Object?>,
  );

  @override
  Future<CodeSent> requestVerifyCode(String email) async => CodeSent.fromJson(
    (await _api.post('/me/verify/code', {'email': email.trim()}))!
        as Map<String, Object?>,
  );

  @override
  Future<UserProfile> verifyUniversityEmail(String email, String code) async =>
      UserProfile.fromJson(
        (await _api.post('/me/verify', {'email': email.trim(), 'code': code}))!
            as Map<String, Object?>,
      );
}
