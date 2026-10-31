import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('unknown values from a newer server fall back safely', () {
    final c = IssueCard.fromJson({
      'id': 'i1',
      'category': 'parking',
      'status': 'escalated',
      'visibility': 'archived',
      'title': 'T',
      'createdAt': 'not a date',
    });
    expect(c.category, IssueCategory.other);
    expect(c.status, IssueStatus.open);
    expect(c.visibility, ContentVisibility.visible);
    expect(c.anonymous, isTrue);
    expect(c.createdAt.millisecondsSinceEpoch, 0);
  });

  test('status machine for officials', () {
    expect(IssueStatus.open.next, contains(IssueStatus.rejected));
    expect(IssueStatus.inProgress.next, [
      IssueStatus.solved,
      IssueStatus.rejected,
    ]);
    expect(IssueStatus.solved.next, isEmpty);
    expect(IssueStatus.parse('in_progress'), IssueStatus.inProgress);
    expect(IssueSort.newest.wire, 'new');
    expect(ReportReason.personalInfo.wire, 'personal_info');
  });

  test('an issue survives a JSON round trip (offline copy)', () {
    final issue = Issue.fromJson({
      'id': 'i1',
      'category': 'safety',
      'private': true,
      'title': 'Broken light near gate',
      'status': 'acknowledged',
      'author': {'name': 'Rafi', 'verified': true},
      'createdAt': '2026-10-28T09:00:00Z',
      'body': 'Dark at night',
      'images': [
        {'id': 'a', 'width': 10, 'height': 20},
      ],
      'timeline': [
        {
          'from': 'open',
          'to': 'acknowledged',
          'actorKind': 'authority',
          'actorTitle': 'Proctor Office',
          'createdAt': '2026-10-28T10:00:00Z',
        },
      ],
      'can': {'reopen': true},
    });
    final again = Issue.fromJson(issue.toJson());
    expect(again.card.private, isTrue);
    expect(again.card.author?.name, 'Rafi');
    expect(again.images.single.aspect, 0.5);
    expect(again.timeline.single.actor, TimelineActor.authority);
    expect(again.can.reopen, isTrue);
    expect(again.card.createdAt, issue.card.createdAt);
    expect(IssueCategory.safety.isPrivate, isTrue);
  });

  test('comments: handles, officials, removed', () {
    final c = IssueComment.fromJson({
      'id': 'c1',
      'kind': 'official',
      'officialTitle': 'Hall Provost',
      'author': {'name': 'Dr. Karim', 'verified': true},
      'body': 'Fixed tomorrow',
      'visibility': 'removed',
      'removedReason': 'Names a person',
      'createdAt': '2026-10-28T09:00:00Z',
    });
    expect(c.official, isTrue);
    expect(c.visibility, ContentVisibility.removed);
    expect(IssueComment.fromJson(c.toJson()).officialTitle, 'Hall Provost');
  });

  group('campus social (CAMPUS_SOCIAL.md)', () {
    test('cards without a kind are issues (older servers and saved feeds)', () {
      final c = IssueCard.fromJson({
        'id': 'i1',
        'category': 'hostel',
        'title': 'No water',
        'status': 'open',
        'createdAt': '2026-10-28T09:00:00Z',
        'voted': true,
        'thumbnail': 'img1',
      });
      expect(c.kind, PostKind.issue);
      expect(c.shownReaction, Reaction.meToo);
      expect(c.shownImages.single.id, 'img1');
    });

    test('a poll with reactions reads and saves the same', () {
      final c = IssueCard.fromJson({
        'id': 'p1',
        'kind': 'poll',
        'category': 'lost_found',
        'title': '',
        'preview': 'Best canteen?',
        'status': 'open',
        'meTooCount': 5,
        'reactions': {'like': 3, 'haha': 2, 'angry': 9, 'wow': 0},
        'myReaction': 'haha',
        'voted': true,
        'images': [
          {'id': 'a', 'width': 100, 'height': 50},
        ],
        'poll': {
          'options': [
            {'id': 'o1', 'label': 'Bot tola', 'votes': null},
            {'id': 'o2', 'label': 'TSC', 'votes': null},
          ],
          'totalVotes': 12,
          'myVote': null,
          'closesAt': '2026-11-03T10:00:00Z',
          'closed': false,
        },
        'createdAt': '2026-10-28T09:00:00Z',
      });
      expect(c.kind, PostKind.poll);
      expect(c.category, IssueCategory.lostFound);
      expect(c.reactions, {Reaction.like: 3, Reaction.haha: 2});
      expect(c.topReactions(), [Reaction.like, Reaction.haha]);
      expect(c.poll!.resultsShown, isFalse);
      expect(c.poll!.isClosed(DateTime.utc(2026, 11, 3, 10)), isTrue);
      final back = IssueCard.fromJson(c.toJson());
      expect(back.toJson(), c.toJson());
      expect(back.poll!.totalVotes, 12);
    });

    test('changing a reaction moves one count; taking it back removes it', () {
      final c = IssueCard(
        id: 'p1',
        kind: PostKind.post,
        category: IssueCategory.general,
        title: '',
        status: IssueStatus.open,
        createdAt: DateTime.utc(2026),
        meTooCount: 3,
        reactions: const {Reaction.like: 2, Reaction.haha: 1},
        voted: true,
        myReaction: Reaction.haha,
      );
      final wow = c.reacted(Reaction.wow);
      expect(wow.meTooCount, 3);
      expect(wow.reactions, {Reaction.like: 2, Reaction.wow: 1});
      expect(wow.myReaction, Reaction.wow);
      final none = wow.reacted(null);
      expect(none.meTooCount, 2);
      expect(none.voted, isFalse);
      expect(none.reactions, {Reaction.like: 2});
      expect(none.myReaction, isNull);
    });

    test('drafts send only what their kind takes', () {
      const poll = IssueDraft(
        kind: PostKind.poll,
        category: IssueCategory.general,
        title: 'ignored',
        body: ' Which day? ',
        pollOptions: [' Fri ', 'Sat'],
        pollDays: 7,
      );
      expect(poll.toJson(), {
        'kind': 'poll',
        'category': 'general',
        'body': 'Which day?',
        'locationLabel': '',
        'anonymous': true,
        'imageIds': <String>[],
        'pollOptions': ['Fri', 'Sat'],
        'pollDays': 7,
      });
      expect(IssueDraft.bodyRange(PostKind.post), (0, 3000));
      expect(IssueCategory.forPosts, isNot(contains(IssueCategory.safety)));
    });

    test('comments carry replies and likes', () {
      final c = IssueComment.fromJson({
        'id': 'c2',
        'body': 'Me too',
        'parentId': 'c1',
        'likeCount': 4,
        'liked': true,
        'createdAt': '2026-10-28T09:00:00Z',
      });
      expect(c.parentId, 'c1');
      expect(c.copyWith(likeCount: 5, liked: false).likeCount, 5);
      expect(IssueComment.fromJson(c.toJson()).liked, isTrue);
    });
  });
}
