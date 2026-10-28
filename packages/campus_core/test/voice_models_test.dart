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
}
