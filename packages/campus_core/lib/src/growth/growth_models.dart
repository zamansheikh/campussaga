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
  );

  final String id;
  final String title;
  final String body;
  final CampaignStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? settlesAt;
  final List<CampaignPrize> prizes;
  final int myScore;

  /// Null when not ranked (no qualified invites yet, or not taking part).
  final int? myRank;
  final String rulesUrl;

  /// Set on `GET /campaigns/{id}` for a winner.
  final CampaignWin? won;

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

  Campaign copyWith({CampaignWin? won}) => Campaign(
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
