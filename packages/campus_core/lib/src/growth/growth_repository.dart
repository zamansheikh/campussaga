import 'growth_models.dart';

/// Invites, badges, student profiles and prize campaigns. Every method
/// throws a `Failure`.
abstract interface class GrowthRepository {
  /// My invite code and link, how many friends I invited and who is still
  /// pending.
  Future<ReferralStats> referrals();

  /// Tells the server whose link brought me ([source] is `link` or `join`).
  /// Rejected with `REFERRAL_TOO_LATE`, `ALREADY_REFERRED`, `REFERRAL_SELF`
  /// or `REFERRAL_NOT_FOUND`; callers ignore those.
  Future<void> claimReferral(String code, {required String source});

  Future<MyBadges> myBadges();

  /// Shows [key] by my name, or none (null). Rejected with `BADGE_NOT_HELD`
  /// or `BADGE_PRIVATE`. Returns what is shown now.
  Future<BadgeRef?> setFeaturedBadge(String? key);

  /// Another student's page. Not found when blocked.
  Future<StudentProfile> studentProfile(String id);

  /// Campaigns I can see: live, or announced in the last 30 days. Text
  /// comes in [lang] (`en` or `bn`).
  Future<List<Campaign>> campaigns({String lang = 'en'});

  Future<Campaign> campaign(String id, {String lang = 'en'});

  Future<Leaderboard> leaderboard(String id, LeaderboardScope scope);

  /// A winner sends where to deliver the prize. Rejected with
  /// `NOT_A_WINNER` or `ALREADY_CLAIMED`.
  Future<void> claimPrize(String id, PrizeClaim claim);

  /// The section challenge board: top sections and mine.
  Future<SectionBoard> sections(String id);

  /// A finisher in the reward sends the mobile number to get it. Rejected
  /// with `NOT_A_FINISHER`, `NO_REWARD`, `ALREADY_CLAIMED` or
  /// `INVALID_PHONE`.
  Future<void> claimFinisherReward(String id, String phone);
}
