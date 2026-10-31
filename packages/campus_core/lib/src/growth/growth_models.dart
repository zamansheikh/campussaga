import '../sponsors/sponsor_models.dart';
import '../voice/voice_models.dart';

DateTime? _time(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

Map<String, Object?>? _map(Object? v) => v is Map<String, Object?> ? v : null;

/// A badge a student holds or shows by their name: its key and tier
/// (1 bronze, 2 silver, 3 gold; 0 for badges without tiers).
class BadgeRef {
  const BadgeRef({required this.key, this.tier = 0});

  /// From `{key, tier}`; a plain key string works too. Null for anything else.
  static BadgeRef? parse(Object? v) {
    if (v is String && v.isNotEmpty) return BadgeRef(key: v);
    final m = _map(v);
    final key = m?['key'];
    if (m == null || key is! String || key.isEmpty) return null;
    return BadgeRef(key: key, tier: _int(m['tier']));
  }

  final String key;
  final int tier;

  Map<String, Object?> toJson() => {'key': key, 'tier': tier};

  @override
  bool operator ==(Object other) =>
      other is BadgeRef && other.key == key && other.tier == tier;

  @override
  int get hashCode => Object.hash(key, tier);
}

/// A badge earned by a student (their own, or a public one on a profile).
class EarnedBadge {
  const EarnedBadge({
    required this.key,
    this.tier = 0,
    this.private = false,
    this.earnedAt,
  });

  factory EarnedBadge.fromJson(Map<String, Object?> json) => EarnedBadge(
    key: json['key']! as String,
    tier: _int(json['tier']),
    private: json['private'] as bool? ?? false,
    earnedAt: _time(json['earnedAt']),
  );

  final String key;
  final int tier;

  /// Only the owner sees it; it can't be shown by their name.
  final bool private;
  final DateTime? earnedAt;

  BadgeRef get ref => BadgeRef(key: key, tier: tier);
}

/// A badge that exists: its tier thresholds, so locked ones can say how to
/// earn them.
class BadgeInfo {
  const BadgeInfo({
    required this.key,
    this.tiers = const [],
    this.private = false,
  });

  factory BadgeInfo.fromJson(Map<String, Object?> json) => BadgeInfo(
    key: json['key']! as String,
    tiers: [
      for (final t in (json['tiers'] as List<Object?>?) ?? const [])
        if (t is num) t.toInt(),
    ],
    private: json['private'] as bool? ?? false,
  );

  final String key;

  /// Bronze, silver and gold thresholds; empty when there are no tiers.
  final List<int> tiers;
  final bool private;
}

/// `GET /me/badges`.
class MyBadges {
  const MyBadges({this.badges = const [], this.all = const [], this.featured});

  factory MyBadges.fromJson(Map<String, Object?> json) => MyBadges(
    badges: [
      for (final b in (json['badges'] as List<Object?>?) ?? const [])
        EarnedBadge.fromJson(b! as Map<String, Object?>),
    ],
    all: [
      for (final b in (json['all'] as List<Object?>?) ?? const [])
        BadgeInfo.fromJson(b! as Map<String, Object?>),
    ],
    featured: BadgeRef.parse(json['featured']),
  );

  final List<EarnedBadge> badges;
  final List<BadgeInfo> all;
  final BadgeRef? featured;

  EarnedBadge? held(String key) {
    for (final b in badges) {
      if (b.key == key) return b;
    }
    return null;
  }

  BadgeInfo? info(String key) {
    for (final b in all) {
      if (b.key == key) return b;
    }
    return null;
  }

  /// Badges not earned yet, from [all].
  List<BadgeInfo> get locked => [
    for (final i in all)
      if (held(i.key) == null) i,
  ];

  MyBadges withFeatured(BadgeRef? featured) =>
      MyBadges(badges: badges, all: all, featured: featured);
}

/// A friend who joined with my link and isn't counted yet.
class PendingFriend {
  const PendingFriend({
    required this.name,
    this.verified = false,
    this.activeDays = 0,
    this.createdAt,
  });

  factory PendingFriend.fromJson(Map<String, Object?> json) => PendingFriend(
    name: json['name'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
    activeDays: _int(json['activeDays']),
    createdAt: _time(json['createdAt']),
  );

  final String name;
  final bool verified;

  /// Days they used the app (3 are needed).
  final int activeDays;
  final DateTime? createdAt;
}

/// `GET /me/referrals`.
class ReferralStats {
  const ReferralStats({
    required this.code,
    required this.link,
    this.invited = 0,
    this.joined = 0,
    this.pending = const [],
    this.recent = const [],
  });

  factory ReferralStats.fromJson(Map<String, Object?> json) => ReferralStats(
    code: json['code'] as String? ?? '',
    link: json['link'] as String? ?? '',
    invited: _int(json['invited']),
    joined: _int(json['joined']),
    pending: [
      for (final p in (json['pending'] as List<Object?>?) ?? const [])
        PendingFriend.fromJson(p! as Map<String, Object?>),
    ],
    recent: [
      for (final r in (json['recent'] as List<Object?>?) ?? const [])
        (r! as Map<String, Object?>)['name'] as String? ?? '',
    ],
  );

  final String code;
  final String link;
  final int invited;
  final int joined;
  final List<PendingFriend> pending;

  /// Names of friends who joined lately.
  final List<String> recent;
}

/// A student's page that others can open (`GET /users/{id}/profile`).
/// Never has an email. The photo fields are null unless the viewer may see
/// the photo.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    this.verified = false,
    this.universityName = '',
    this.department,
    this.batch,
    this.joinedAt,
    this.photoVersion,
    this.googlePhotoUrl,
    this.featuredBadge,
    this.badges = const [],
    this.roles = const [],
    this.invitesJoined = 0,
    this.posts = const [],
  });

  factory StudentProfile.fromJson(Map<String, Object?> json) => StudentProfile(
    id: json['id']! as String,
    name: json['name'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
    universityName: _map(json['university'])?['name'] as String? ?? '',
    department: json['department'] as String?,
    batch: json['batch'] as String?,
    joinedAt: _time(json['joinedAt']),
    photoVersion: json['photoVersion'] as String?,
    googlePhotoUrl: json['googlePhotoUrl'] as String?,
    featuredBadge: BadgeRef.parse(json['featuredBadge']),
    badges: [
      for (final b in (json['badges'] as List<Object?>?) ?? const [])
        EarnedBadge.fromJson(b! as Map<String, Object?>),
    ],
    roles: [
      for (final r in (json['roles'] as List<Object?>?) ?? const [])
        if (r is String) r,
    ],
    invitesJoined: _int(json['invitesJoined']),
    posts: [
      for (final p in (json['posts'] as List<Object?>?) ?? const [])
        IssueCard.fromJson(p! as Map<String, Object?>),
    ],
  );

  final String id;
  final String name;
  final bool verified;
  final String universityName;
  final String? department;
  final String? batch;

  /// Month precision.
  final DateTime? joinedAt;
  final String? photoVersion;
  final String? googlePhotoUrl;
  final BadgeRef? featuredBadge;
  final List<EarnedBadge> badges;

  /// `cr`, `campus_admin`, `bus_rep`, `official`.
  final List<String> roles;
  final int invitesJoined;

  /// Their named Campus posts (never anonymous ones), latest first.
  final List<IssueCard> posts;

  String get classLine =>
      [department, batch].where((v) => v != null && v.isNotEmpty).join(' · ');
}

/// One prize: a rank (or range of ranks) and what it wins.
class CampaignPrize {
  const CampaignPrize({
    required this.rankFrom,
    required this.rankTo,
    required this.title,
  });

  factory CampaignPrize.fromJson(Map<String, Object?> json) => CampaignPrize(
    rankFrom: _int(json['rankFrom']),
    rankTo: _int(json['rankTo']),
    title: json['title'] as String? ?? '',
  );

  final int rankFrom;
  final int rankTo;
  final String title;

  bool get isRange => rankTo > rankFrom;
}

/// The student's win, once winners are announced.
class CampaignWin {
  const CampaignWin({
    required this.rank,
    required this.prize,
    this.claimed = false,
  });

  factory CampaignWin.fromJson(Map<String, Object?> json) => CampaignWin(
    rank: _int(json['rank']),
    prize: json['prize'] as String? ?? '',
    claimed: json['claimed'] as bool? ?? false,
  );

  final int rank;
  final String prize;
  final bool claimed;

  CampaignWin copyWith({bool? claimed}) =>
      CampaignWin(rank: rank, prize: prize, claimed: claimed ?? this.claimed);
}

enum CampaignStatus {
  draft,
  live,
  ended,
  announced;

  static CampaignStatus parse(Object? v) => CampaignStatus.values.firstWhere(
    (s) => s.name == v,
    orElse: () => CampaignStatus.ended,
  );
}

/// A campaign's point values (`scoring`). A 0 turns that way off.
class CampaignScoring {
  const CampaignScoring({
    this.invite = 10,
    this.otherCampus = 5,
    this.pioneer = 5,
    this.friendSection = 3,
    this.joinSection = 2,
    this.bloodDonor = 3,
    this.busShare = 2,
    this.busShareDays = 10,
    this.sectionSetup = 15,
    this.sectionSetupMax = 2,
    this.pioneerFirst = 20,
    this.minOtherCampus = 2,
    this.minOwnCampus = 3,
  });

  /// Missing keys (or an older server) take the defaults.
  factory CampaignScoring.fromJson(Map<String, Object?>? json) {
    const d = CampaignScoring();
    int v(String k, int def) => (json?[k] as num?)?.toInt() ?? def;
    return CampaignScoring(
      invite: v('invite', d.invite),
      otherCampus: v('otherCampus', d.otherCampus),
      pioneer: v('pioneer', d.pioneer),
      friendSection: v('friendSection', d.friendSection),
      joinSection: v('joinSection', d.joinSection),
      bloodDonor: v('bloodDonor', d.bloodDonor),
      busShare: v('busShare', d.busShare),
      busShareDays: v('busShareDays', d.busShareDays),
      sectionSetup: v('sectionSetup', d.sectionSetup),
      sectionSetupMax: v('sectionSetupMax', d.sectionSetupMax),
      pioneerFirst: v('pioneerFirst', d.pioneerFirst),
      minOtherCampus: v('minOtherCampus', d.minOtherCampus),
      minOwnCampus: v('minOwnCampus', d.minOwnCampus),
    );
  }

  final int invite;
  final int otherCampus;
  final int pioneer;
  final int friendSection;
  final int joinSection;
  final int bloodDonor;
  final int busShare;
  final int busShareDays;
  final int sectionSetup;
  final int sectionSetupMax;
  final int pioneerFirst;

  /// Friends from other universities needed to be ranked and win (0: none).
  final int minOtherCampus;

  /// Friends from my own university needed to be ranked and win (0: none).
  final int minOwnCampus;

  /// The prize race has an entry rule.
  bool get hasRace => minOtherCampus > 0 || minOwnCampus > 0;
}

/// How a mission's points come: per friend, once, per day, per section.
enum MissionPer {
  friend,
  once,
  day,
  section;

  static MissionPer parse(Object? v) => MissionPer.values.firstWhere(
    (p) => p.name == v,
    orElse: () => MissionPer.once,
  );
}

/// One way to earn points, with my progress (`missions` on a campaign).
class CampaignMission {
  const CampaignMission({
    required this.key,
    required this.points,
    required this.per,
    this.count = 0,
    this.max,
    this.earned = 0,
  });

  factory CampaignMission.fromJson(Map<String, Object?> json) =>
      CampaignMission(
        key: json['key'] as String? ?? '',
        points: _int(json['points']),
        per: MissionPer.parse(json['per']),
        count: _int(json['count']),
        max: (json['max'] as num?)?.toInt(),
        earned: _int(json['earned']),
      );

  /// invite, otherCampus, pioneer, friendSection, joinSection, bloodDonor,
  /// busShare, sectionSetup.
  final String key;
  final int points;
  final MissionPer per;

  /// Times counted: friends, days, sections; 0 or 1 for a once.
  final int count;

  /// The limit; null: no limit (friends).
  final int? max;
  final int earned;

  /// A once mission done, or a limited one used up.
  bool get done => max != null && count >= max!;
}

/// My CR section that doesn't count yet, and how far it is (`section`).
class CampaignSectionProgress {
  const CampaignSectionProgress({
    required this.groupId,
    required this.name,
    this.slots = 0,
    this.members = 0,
  });

  factory CampaignSectionProgress.fromJson(Map<String, Object?> json) =>
      CampaignSectionProgress(
        groupId: json['groupId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slots: _int(json['slots']),
        members: _int(json['members']),
      );

  final String groupId;
  final String name;

  /// Classes in the weekly routine, and verified members besides me; each
  /// needs [need].
  final int slots;
  final int members;

  static const need = 5;
}

/// What makes a champion section (`sectionChallenge`): verified members
/// and routine classes.
class SectionChallenge {
  const SectionChallenge({this.members = 25, this.slots = 5});

  factory SectionChallenge.fromJson(Map<String, Object?>? json) =>
      SectionChallenge(
        members: (json?['members'] as num?)?.toInt() ?? 25,
        slots: (json?['slots'] as num?)?.toInt() ?? 5,
      );

  final int members;
  final int slots;
}

/// The reward for the first students who enter the prize race
/// (`finisherReward`).
class FinisherReward {
  const FinisherReward({
    required this.title,
    required this.count,
    this.left = 0,
  });

  factory FinisherReward.fromJson(Map<String, Object?> json) => FinisherReward(
    title: json['title'] as String? ?? '',
    count: _int(json['count']),
    left: _int(json['left']),
  );

  /// "20 TK mobile recharge".
  final String title;

  /// For the first [count] finishers; [left] still free.
  final int count;
  final int left;
}

/// My place among the finishers (`finisher`).
class CampaignFinisher {
  const CampaignFinisher({
    required this.position,
    this.inReward = false,
    this.claimed = false,
    this.sent = false,
  });

  factory CampaignFinisher.fromJson(Map<String, Object?> json) =>
      CampaignFinisher(
        position: _int(json['position']),
        inReward: json['inReward'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
        sent: json['sent'] as bool? ?? false,
      );

  final int position;

  /// Among the first who get the reward.
  final bool inReward;

  /// I sent my number; the team sent the reward.
  final bool claimed;
  final bool sent;

  CampaignFinisher copyWith({bool? claimed}) => CampaignFinisher(
    position: position,
    inReward: inReward,
    claimed: claimed ?? this.claimed,
    sent: sent,
  );
}

/// A section on the section challenge board.
class SectionRow {
  const SectionRow({
    required this.rank,
    required this.groupId,
    required this.name,
    this.university = '',
    this.members = 0,
    this.slots = 0,
    this.champion = false,
  });

  factory SectionRow.fromJson(Map<String, Object?> json) => SectionRow(
    rank: _int(json['rank']),
    groupId: json['groupId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    university: json['university'] as String? ?? '',
    members: _int(json['members']),
    slots: _int(json['slots']),
    champion: json['champion'] as bool? ?? false,
  );

  final int rank;
  final String groupId;
  final String name;
  final String university;

  /// Verified members, and classes in the routine.
  final int members;
  final int slots;
  final bool champion;
}

/// The top sections of a campaign, and mine (`GET /campaigns/{id}/sections`).
class SectionBoard {
  const SectionBoard({this.rows = const [], this.mine});

  factory SectionBoard.fromJson(Map<String, Object?> json) => SectionBoard(
    rows: [
      for (final r in (json['rows'] as List<Object?>?) ?? const [])
        SectionRow.fromJson(r! as Map<String, Object?>),
    ],
    mine: _map(json['mine']) == null
        ? null
        : SectionRow.fromJson(_map(json['mine'])!),
  );

  final List<SectionRow> rows;
  final SectionRow? mine;
}

/// A prize campaign (`GET /campaigns`, `GET /campaigns/{id}`). Text is in
/// the student's language.
class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.status,
    this.body = '',
    this.startsAt,
    this.endsAt,
    this.settlesAt,
    this.prizes = const [],
    this.myScore = 0,
    this.myRank,
    this.rulesUrl = '',
    this.won,
    this.bannerUrl,
    this.scoring = const CampaignScoring(),
    this.missions = const [],
    this.section,
    this.myOtherCampus = 0,
    this.myOwnCampus = 0,
    this.eligible = true,
    this.sectionPrize = '',
    this.sectionChallenge = const SectionChallenge(),
    this.finisherReward,
    this.finisher,
    this.sponsor,
  });

  factory Campaign.fromJson(Map<String, Object?> json) => Campaign(
    id: json['id']! as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    status: CampaignStatus.parse(json['status']),
    startsAt: _time(json['startsAt']),
    endsAt: _time(json['endsAt']),
    settlesAt: _time(json['settlesAt']),
    prizes: [
      for (final p in (json['prizes'] as List<Object?>?) ?? const [])
        CampaignPrize.fromJson(p! as Map<String, Object?>),
    ],
    myScore: _int(json['myScore']),
    myRank: (json['myRank'] as num?)?.toInt(),
    rulesUrl: json['rulesUrl'] as String? ?? '',
    won: _map(json['iWon']) == null
        ? null
        : CampaignWin.fromJson(_map(json['iWon'])!),
    bannerUrl: json['bannerUrl'] as String?,
    scoring: CampaignScoring.fromJson(_map(json['scoring'])),
    missions: [
      for (final m in (json['missions'] as List<Object?>?) ?? const [])
        CampaignMission.fromJson(m! as Map<String, Object?>),
    ],
    section: _map(json['section']) == null
        ? null
        : CampaignSectionProgress.fromJson(_map(json['section'])!),
    myOtherCampus: _int(json['myOtherCampus']),
    myOwnCampus: _int(json['myOwnCampus']),
    eligible: json['eligible'] as bool? ?? true,
    sectionPrize: json['sectionPrize'] as String? ?? '',
    sectionChallenge: SectionChallenge.fromJson(_map(json['sectionChallenge'])),
    finisherReward: _map(json['finisherReward']) == null
        ? null
        : FinisherReward.fromJson(_map(json['finisherReward'])!),
    finisher: _map(json['finisher']) == null
        ? null
        : CampaignFinisher.fromJson(_map(json['finisher'])!),
    sponsor: CampaignSponsor.fromJson(json['sponsor']),
  );

  final String id;
  final String title;
  final String body;
  final CampaignStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? settlesAt;
  final List<CampaignPrize> prizes;

  /// My points.
  final int myScore;

  /// Null when not ranked (no points yet, or not taking part).
  final int? myRank;
  final String rulesUrl;

  /// Set on `GET /campaigns/{id}` for a winner.
  final CampaignWin? won;

  /// The team's banner photo, a path under the API base
  /// ("/campaigns/{id}/banner?v=…"); null: the app draws its own.
  final String? bannerUrl;

  /// The point values.
  final CampaignScoring scoring;

  /// Ways to earn, with my progress (`GET /campaigns/{id}` only).
  final List<CampaignMission> missions;

  /// My CR section that doesn't count yet (detail only).
  final CampaignSectionProgress? section;

  /// My counted friends at other universities, and at mine.
  final int myOtherCampus;
  final int myOwnCampus;

  /// I have the friends (from mine and other universities) needed to be
  /// ranked: in the prize race (an older server: always).
  final bool eligible;

  /// Friends from other universities I still need to be ranked.
  int get otherCampusNeeded =>
      eligible ? 0 : (scoring.minOtherCampus - myOtherCampus).clamp(0, 999);

  /// Friends from my university I still need to be ranked.
  int get ownCampusNeeded =>
      eligible ? 0 : (scoring.minOwnCampus - myOwnCampus).clamp(0, 999);

  /// Not in the prize race yet.
  bool get outOfRace => ownCampusNeeded > 0 || otherCampusNeeded > 0;

  /// The team's prize for the top section; empty: badges only.
  final String sectionPrize;
  final SectionChallenge sectionChallenge;

  /// For the first students in the prize race; null: none.
  final FinisherReward? finisherReward;

  /// My finisher place, once I'm in the race (detail only).
  final CampaignFinisher? finisher;

  /// The brand behind the campaign ("Powered by"), or null.
  final CampaignSponsor? sponsor;

  /// Running at [now].
  bool isLive(DateTime now) =>
      status == CampaignStatus.live &&
      (endsAt == null || endsAt!.isAfter(now)) &&
      (startsAt == null || !startsAt!.isAfter(now));

  /// The best prize (lowest ranks), or null.
  CampaignPrize? get topPrize {
    if (prizes.isEmpty) return null;
    return ([
      ...prizes,
    ]..sort((a, b) => a.rankFrom.compareTo(b.rankFrom))).first;
  }

  Campaign copyWith({CampaignWin? won, CampaignFinisher? finisher}) => Campaign(
    id: id,
    title: title,
    body: body,
    status: status,
    startsAt: startsAt,
    endsAt: endsAt,
    settlesAt: settlesAt,
    prizes: prizes,
    myScore: myScore,
    myRank: myRank,
    rulesUrl: rulesUrl,
    won: won ?? this.won,
    bannerUrl: bannerUrl,
    scoring: scoring,
    missions: missions,
    section: section,
    myOtherCampus: myOtherCampus,
    myOwnCampus: myOwnCampus,
    eligible: eligible,
    sectionPrize: sectionPrize,
    sectionChallenge: sectionChallenge,
    finisherReward: finisherReward,
    finisher: finisher ?? this.finisher,
    sponsor: sponsor,
  );
}

enum LeaderboardScope {
  all('all'),
  university('university');

  const LeaderboardScope(this.wire);

  final String wire;
}

/// One line of a campaign leaderboard.
class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    this.university = '',
    this.featuredBadge,
    this.me = false,
    this.userId,
  });

  factory LeaderboardRow.fromJson(Map<String, Object?> json) => LeaderboardRow(
    rank: _int(json['rank']),
    name: json['name'] as String? ?? '',
    university: json['university'] as String? ?? '',
    featuredBadge: BadgeRef.parse(json['featuredBadge']),
    score: _int(json['score']),
    me: json['me'] as bool? ?? false,
    userId: (json['userId'] ?? json['id']) as String?,
  );

  final int rank;
  final String name;
  final String university;
  final BadgeRef? featuredBadge;
  final int score;
  final bool me;

  /// Missing for a student who hides their name: the row can't open a
  /// profile.
  final String? userId;
}

/// `GET /campaigns/{id}/leaderboard`.
class Leaderboard {
  const Leaderboard({this.rows = const [], this.me, this.updatedAt});

  factory Leaderboard.fromJson(Map<String, Object?> json) => Leaderboard(
    rows: [
      for (final r in (json['rows'] as List<Object?>?) ?? const [])
        LeaderboardRow.fromJson(r! as Map<String, Object?>),
    ],
    me: _map(json['me']) == null
        ? null
        : LeaderboardRow.fromJson(_map(json['me'])!),
    updatedAt: _time(json['updatedAt']),
  );

  final List<LeaderboardRow> rows;
  final LeaderboardRow? me;
  final DateTime? updatedAt;
}

/// What a winner sends to get the prize.
class PrizeClaim {
  const PrizeClaim({
    required this.fullName,
    required this.phone,
    required this.address,
    this.note = '',
  });

  final String fullName;
  final String phone;
  final String address;
  final String note;

  Map<String, Object?> toJson() => {
    'fullName': fullName.trim(),
    'phone': phone.trim(),
    'address': address.trim(),
    if (note.trim().isNotEmpty) 'note': note.trim(),
  };
}
