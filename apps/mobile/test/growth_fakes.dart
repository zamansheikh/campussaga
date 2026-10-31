import 'package:campus_core/campus_core.dart';

/// In-memory invites, badges, profiles and campaigns.
class FakeGrowthRepository implements GrowthRepository {
  ReferralStats stats = const ReferralStats(
    code: 'abcd1234',
    link: 'https://varsitykotha.com/r/abcd1234',
  );
  MyBadges badges = const MyBadges();
  final profiles = <String, StudentProfile>{};
  List<Campaign> campaignList = [];
  final campaignsById = <String, Campaign>{};
  final boards = <LeaderboardScope, Leaderboard>{};

  /// Every call fails with this (when set).
  Failure? failure;
  Failure? referralFailure;
  Failure? featureFailure;
  Failure? claimFailure;

  final claimedReferrals = <(String, String)>[];
  final featureCalls = <String?>[];
  final prizeClaims = <(String, PrizeClaim)>[];
  final scopesAsked = <LeaderboardScope>[];
  final finisherClaims = <(String, String)>[];
  SectionBoard sectionBoard = const SectionBoard();
  int referralsCalls = 0;

  @override
  Future<ReferralStats> referrals() async {
    referralsCalls++;
    if (failure != null) throw failure!;
    return stats;
  }

  @override
  Future<void> claimReferral(String code, {required String source}) async {
    claimedReferrals.add((code, source));
    if (referralFailure != null) throw referralFailure!;
  }

  @override
  Future<MyBadges> myBadges() async {
    if (failure != null) throw failure!;
    return badges;
  }

  @override
  Future<BadgeRef?> setFeaturedBadge(String? key) async {
    featureCalls.add(key);
    if (featureFailure != null) throw featureFailure!;
    final now = key == null
        ? null
        : BadgeRef(key: key, tier: badges.held(key)?.tier ?? 0);
    badges = badges.withFeatured(now);
    return now;
  }

  @override
  Future<StudentProfile> studentProfile(String id) async {
    if (failure != null) throw failure!;
    return profiles[id] ?? (throw const NotFoundFailure(code: 'NOT_FOUND'));
  }

  @override
  Future<List<Campaign>> campaigns({String lang = 'en'}) async {
    if (failure != null) throw failure!;
    return campaignList;
  }

  @override
  Future<Campaign> campaign(String id, {String lang = 'en'}) async {
    if (failure != null) throw failure!;
    return campaignsById[id] ??
        campaignList.where((c) => c.id == id).firstOrNull ??
        (throw const NotFoundFailure(code: 'NOT_FOUND'));
  }

  @override
  Future<Leaderboard> leaderboard(String id, LeaderboardScope scope) async {
    scopesAsked.add(scope);
    if (failure != null) throw failure!;
    return boards[scope] ?? const Leaderboard();
  }

  @override
  Future<void> claimPrize(String id, PrizeClaim claim) async {
    if (claimFailure != null) throw claimFailure!;
    prizeClaims.add((id, claim));
  }

  @override
  Future<SectionBoard> sections(String id) async {
    if (failure != null) throw failure!;
    return sectionBoard;
  }

  @override
  Future<void> claimFinisherReward(String id, String phone) async {
    if (claimFailure != null) throw claimFailure!;
    finisherClaims.add((id, phone));
  }
}

/// A badge list as the server sends it for a student with some badges.
MyBadges sampleBadges({BadgeRef? featured}) => MyBadges(
  badges: [
    const EarnedBadge(key: 'verified'),
    const EarnedBadge(key: 'connector', tier: 2),
    EarnedBadge(
      key: 'helper',
      tier: 1,
      private: true,
      earnedAt: DateTime(2026),
    ),
  ],
  all: const [
    BadgeInfo(key: 'verified'),
    BadgeInfo(key: 'connector', tiers: [5, 25, 100]),
    BadgeInfo(key: 'helper', tiers: [10, 50, 200], private: true),
    BadgeInfo(key: 'bug_hunter', tiers: [1, 3, 10]),
  ],
  featured: featured,
);

/// A live campaign ending in [endsIn] from [now].
Campaign sampleCampaign({
  required DateTime now,
  Duration endsIn = const Duration(days: 5, hours: 3),
  CampaignStatus status = CampaignStatus.live,
  int? rank = 12,
  int score = 4,
  CampaignWin? won,
  List<CampaignMission> missions = const [],
  CampaignSectionProgress? section,
  bool eligible = true,
  int myOtherCampus = 2,
  int myOwnCampus = 3,
}) => Campaign(
  id: 'c1',
  title: 'Invite and win',
  body: 'Bring classmates who really use the app.',
  status: status,
  startsAt: now.subtract(const Duration(days: 10)),
  endsAt: now.add(endsIn),
  settlesAt: now.add(endsIn + const Duration(days: 7)),
  prizes: const [
    CampaignPrize(rankFrom: 4, rankTo: 10, title: 'Headphones'),
    CampaignPrize(rankFrom: 1, rankTo: 1, title: 'A phone'),
  ],
  myScore: score,
  myRank: rank,
  won: won,
  missions: missions,
  section: section,
  eligible: eligible,
  myOtherCampus: myOtherCampus,
  myOwnCampus: myOwnCampus,
);
