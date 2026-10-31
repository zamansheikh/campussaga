import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('badges: earned, tiers, locked and what is shown by the name', () {
    final b = MyBadges.fromJson({
      'badges': [
        {'key': 'verified', 'tier': 0, 'private': false},
        {
          'key': 'helper',
          'tier': 2,
          'private': true,
          'earnedAt': '2026-10-01T10:00:00Z',
        },
      ],
      'featured': {'key': 'verified', 'tier': 0},
      'all': [
        {'key': 'verified', 'tiers': [], 'private': false},
        {
          'key': 'connector',
          'tiers': [5, 25, 100],
          'private': false,
        },
        {
          'key': 'helper',
          'tiers': [10, 50, 200],
          'private': true,
        },
      ],
    });
    expect(b.badges.map((e) => e.key), ['verified', 'helper']);
    expect(b.held('helper')?.private, isTrue);
    expect(b.held('helper')?.earnedAt, isNotNull);
    expect(b.locked.map((e) => e.key), ['connector']);
    expect(b.info('connector')?.tiers, [5, 25, 100]);
    expect(b.featured, const BadgeRef(key: 'verified'));
    expect(b.withFeatured(null).featured, isNull);
  });

  test('a badge ref reads a map or a plain key', () {
    expect(
      BadgeRef.parse({'key': 'connector', 'tier': 3}),
      const BadgeRef(key: 'connector', tier: 3),
    );
    expect(BadgeRef.parse('cr'), const BadgeRef(key: 'cr'));
    expect(BadgeRef.parse(null), isNull);
    expect(BadgeRef.parse({'tier': 1}), isNull);
  });

  test('referral stats', () {
    final s = ReferralStats.fromJson({
      'code': 'abcd1234',
      'link': 'https://varsitykotha.com/r/abcd1234',
      'invited': 12,
      'joined': 8,
      'pending': [
        {'name': 'Rafi', 'verified': true, 'activeDays': 2},
      ],
      'recent': [
        {'name': 'Mim', 'qualifiedAt': '2026-10-02T00:00:00Z'},
      ],
    });
    expect(s.invited, 12);
    expect(s.joined, 8);
    expect(s.pending.single.activeDays, 2);
    expect(s.pending.single.verified, isTrue);
    expect(s.recent, ['Mim']);
  });

  test('a student profile: no photo fields, named posts come along', () {
    final p = StudentProfile.fromJson({
      'id': 'u9',
      'name': 'Maliha',
      'verified': true,
      'university': {'id': 'x', 'name': 'DIU', 'slug': 'diu'},
      'department': 'CSE',
      'batch': '60',
      'joinedAt': '2026-03-01T00:00:00Z',
      'photoVersion': null,
      'googlePhotoUrl': null,
      'featuredBadge': {'key': 'cr', 'tier': 0},
      'badges': [
        {'key': 'cr', 'tier': 0, 'earnedAt': '2026-04-01T00:00:00Z'},
      ],
      'roles': ['cr'],
      'invitesJoined': 3,
      'posts': [
        {
          'id': 'p1',
          'kind': 'post',
          'category': 'other',
          'preview': 'Hello',
          'status': 'open',
          'createdAt': '2026-10-01T00:00:00Z',
          'author': {'name': 'Maliha', 'id': 'u9'},
        },
      ],
    });
    expect(p.photoVersion, isNull);
    expect(p.googlePhotoUrl, isNull);
    expect(p.universityName, 'DIU');
    expect(p.classLine, 'CSE · 60');
    expect(p.featuredBadge?.key, 'cr');
    expect(p.posts.single.author?.id, 'u9');
    expect(p.roles, ['cr']);
  });

  test('campaigns: prizes, top prize, live window, my win', () {
    final c = Campaign.fromJson({
      'id': 'c1',
      'title': 'Invite and win',
      'status': 'live',
      'startsAt': '2026-10-01T00:00:00Z',
      'endsAt': '2026-11-01T00:00:00Z',
      'settlesAt': '2026-11-08T00:00:00Z',
      'prizes': [
        {'rankFrom': 2, 'rankTo': 5, 'title': 'Headphones'},
        {'rankFrom': 1, 'rankTo': 1, 'title': 'A phone'},
      ],
      'myScore': 4,
      'myRank': 12,
      'rulesUrl': 'https://varsitykotha.com/campaigns/c1',
      'iWon': {'rank': 1, 'prize': 'A phone', 'claimed': false},
    });
    expect(c.topPrize?.title, 'A phone');
    expect(c.prizes.first.isRange, isTrue);
    expect(c.myRank, 12);
    expect(c.won?.claimed, isFalse);
    expect(c.isLive(DateTime.utc(2026, 10, 15)), isTrue);
    expect(c.isLive(DateTime.utc(2026, 11, 2)), isFalse);
    expect(c.won?.copyWith(claimed: true).claimed, isTrue);
    expect(
      Campaign.fromJson({'id': 'c2', 'status': 'weird'}).status,
      CampaignStatus.ended,
    );
  });

  test('leaderboard rows: a hidden student has no id', () {
    final b = Leaderboard.fromJson({
      'rows': [
        {
          'rank': 1,
          'name': 'Mim',
          'university': 'DIU',
          'score': 9,
          'featuredBadge': {'key': 'connector', 'tier': 3},
          'userId': 'u7',
        },
        {'rank': 2, 'name': 'A student at BUET', 'score': 7},
      ],
      'me': {'rank': 12, 'name': 'Rafi', 'score': 4, 'me': true},
      'updatedAt': '2026-10-27T10:00:00Z',
    });
    expect(b.rows.first.userId, 'u7');
    expect(b.rows.first.featuredBadge?.tier, 3);
    expect(b.rows.last.userId, isNull);
    expect(b.me?.me, isTrue);
    expect(b.updatedAt, isNotNull);
  });

  test('the prize claim sends trimmed fields and skips an empty note', () {
    expect(
      const PrizeClaim(
        fullName: ' Rafi Ahmed ',
        phone: '017',
        address: 'Savar',
      ).toJson(),
      {'fullName': 'Rafi Ahmed', 'phone': '017', 'address': 'Savar'},
    );
    expect(
      const PrizeClaim(
        fullName: 'R',
        phone: '1',
        address: 'A',
        note: ' hi ',
      ).toJson()['note'],
      'hi',
    );
  });

  test('profile, author and member carry the new growth fields', () {
    final u = UserProfile.fromJson({
      'id': 'u1',
      'email': 'a@diu.edu.bd',
      'role': 'student',
      'university': null,
      'leaderboardHidden': true,
      'featuredBadge': {'key': 'cr', 'tier': 0},
      'referralCode': 'abcd1234',
    });
    expect(u.leaderboardHidden, isTrue);
    expect(u.featuredBadge?.key, 'cr');
    expect(u.referralCode, 'abcd1234');
    expect(UserProfile.fromJson(u.toJson()).referralCode, 'abcd1234');
    expect(u.withGrowth(leaderboardHidden: false).leaderboardHidden, isFalse);
    expect(u.withGrowth(clearFeaturedBadge: true).featuredBadge, isNull);

    final plain = UserProfile.fromJson({
      'id': 'u1',
      'email': 'a@diu.edu.bd',
      'role': 'student',
    });
    expect(plain.leaderboardHidden, isFalse);
    expect(plain.featuredBadge, isNull);

    final named = PostAuthor.fromJson({
      'name': 'Maliha',
      'id': 'u9',
      'featuredBadge': {'key': 'connector', 'tier': 1},
    });
    expect(named.id, 'u9');
    expect(named.featuredBadge?.tier, 1);
    expect(PostAuthor.fromJson({'name': 'Old'}).id, isNull);

    final m = GroupMember.fromJson({
      'userId': 'u9',
      'name': 'Maliha',
      'featuredBadge': {'key': 'cr'},
    });
    expect(m.featuredBadge?.key, 'cr');
  });
}
