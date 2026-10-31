import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Invites, badges, profiles and campaigns over HTTP (docs/GROWTH.md §5).
class ApiGrowthRepository implements GrowthRepository {
  ApiGrowthRepository(this._api);

  final ApiClient _api;

  static Map<String, Object?> _map(Object? v) => v! as Map<String, Object?>;

  static String _seg(String v) => Uri.encodeComponent(v);

  @override
  Future<ReferralStats> referrals() async =>
      ReferralStats.fromJson(_map(await _api.get('/me/referrals')));

  @override
  Future<void> claimReferral(String code, {required String source}) async {
    await _api.post('/me/referral', {'code': code, 'source': source});
  }

  @override
  Future<MyBadges> myBadges() async =>
      MyBadges.fromJson(_map(await _api.get('/me/badges')));

  @override
  Future<BadgeRef?> setFeaturedBadge(String? key) async {
    final data = _map(await _api.put('/me/featured-badge', {'key': key}));
    return BadgeRef.parse(data['featured']);
  }

  @override
  Future<StudentProfile> studentProfile(String id) async =>
      StudentProfile.fromJson(
        _map(await _api.get('/users/${_seg(id)}/profile')),
      );

  @override
  Future<List<Campaign>> campaigns({String lang = 'en'}) async {
    final data = await _api.get('/campaigns?lang=${_seg(lang)}');
    final list = data is List<Object?>
        ? data
        : (data is Map<String, Object?>
                      ? data['campaigns'] ?? data['items']
                      : null)
                  as List<Object?>? ??
              const [];
    return [for (final c in list) Campaign.fromJson(_map(c))];
  }

  @override
  Future<Campaign> campaign(String id, {String lang = 'en'}) async =>
      Campaign.fromJson(
        _map(await _api.get('/campaigns/${_seg(id)}?lang=${_seg(lang)}')),
      );

  @override
  Future<Leaderboard> leaderboard(String id, LeaderboardScope scope) async =>
      Leaderboard.fromJson(
        _map(
          await _api.get(
            '/campaigns/${_seg(id)}/leaderboard?scope=${scope.wire}',
          ),
        ),
      );

  @override
  Future<void> claimPrize(String id, PrizeClaim claim) async {
    await _api.post('/campaigns/${_seg(id)}/claim', claim.toJson());
  }

  @override
  Future<SectionBoard> sections(String id) async => SectionBoard.fromJson(
    _map(await _api.get('/campaigns/${_seg(id)}/sections')),
  );

  @override
  Future<void> claimFinisherReward(String id, String phone) async {
    await _api.post('/campaigns/${_seg(id)}/finisher-claim', {'phone': phone});
  }
}
