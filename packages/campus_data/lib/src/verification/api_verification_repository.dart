import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Verification by people over HTTP (docs/CAMPUS_ADMINS.md §3).
class ApiVerificationRepository implements VerificationRepository {
  ApiVerificationRepository(this._api);

  final ApiClient _api;

  static Map<String, Object?> _map(Object? v) => v! as Map<String, Object?>;

  static String _seg(String v) => Uri.encodeComponent(v);

  @override
  Future<MyVerification> mine() async =>
      MyVerification.fromJson(_map(await _api.get('/me/verification')));

  @override
  Future<VouchCard> vouchCard(String code) async =>
      VouchCard.fromJson(_map(await _api.get('/vouch/${_seg(code)}')));

  @override
  Future<VouchCard> vouch(String code) async =>
      VouchCard.fromJson(_map(await _api.post('/vouch/${_seg(code)}')));

  @override
  Future<GroupMember> confirmMember(String groupId, String userId) async =>
      GroupMember.fromJson(
        _map(
          await _api.post(
            '/groups/${_seg(groupId)}/members/${_seg(userId)}/confirm',
          ),
        ),
      );

  @override
  Future<void> requestUniversity({
    required String email,
    String? universityId,
    String? universityName,
  }) async {
    await _api.post('/universities/domain-requests', {
      'email': email.trim(),
      'universityId': ?universityId,
      if (universityName != null && universityName.trim().isNotEmpty)
        'universityName': universityName.trim(),
    }, false);
  }
}
