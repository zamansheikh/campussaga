import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('UserProfile reads campusAdmin (false by default) and keeps it', () {
    const base = {
      'id': 'u1',
      'email': 'a@b.c',
      'university': null,
      'role': 'student',
    };
    expect(UserProfile.fromJson(base).campusAdmin, isFalse);
    final admin = UserProfile.fromJson({...base, 'campusAdmin': true});
    expect(admin.campusAdmin, isTrue);
    expect(UserProfile.fromJson(admin.toJson()).campusAdmin, isTrue);
  });

  test('MyVerification reads the progress, the link and the CRs', () {
    final m = MyVerification.fromJson({
      'verified': false,
      'via': null,
      'emailPossible': true,
      'vouches': 1,
      'needed': 2,
      'vouchedBy': [
        {'id': 'a', 'name': 'Nusrat'},
      ],
      'code': 'abc12345',
      'link': 'https://varsitykotha.com/v/abc12345',
      'crs': [
        {
          'groupId': 'g',
          'groupName': 'CSE 61 · A',
          'crId': 'c',
          'crName': 'Rafi',
        },
      ],
    });
    expect(m.verified, isFalse);
    expect(m.emailPossible, isTrue);
    expect(m.vouchedBy.single.name, 'Nusrat');
    expect(m.crs.single.crName, 'Rafi');
    expect(m.link, endsWith('/v/abc12345'));
    expect(VerifiedVia.parse('campus_admin'), VerifiedVia.campusAdmin);
    expect(VerifiedVia.parse('nope'), isNull);
  });

  test('VouchCard and its reasons', () {
    final c = VouchCard.fromJson({
      'student': {
        'id': 's',
        'name': 'Tanvir',
        'department': 'CSE',
        'batch': '61',
      },
      'university': {'id': 'u', 'name': 'Demo University'},
      'vouches': 1,
      'needed': 2,
      'verified': false,
      'alreadyVouched': false,
      'canVouch': false,
      'reason': 'other_university',
    });
    expect(c.student.classLine, 'CSE · 61');
    expect(c.universityName, 'Demo University');
    expect(c.remaining, 1);
    expect(c.reason, VouchReason.otherUniversity);
    for (final r in VouchReason.values) {
      expect(VouchReason.parse(null), isNull);
      expect(r, isNotNull);
    }
    expect(VouchReason.fromErrorCode('VOUCH_LIMIT'), VouchReason.limit);
    expect(
      VouchReason.fromErrorCode('VERIFY_YOURSELF_FIRST'),
      VouchReason.notVerified,
    );
    expect(VouchReason.fromErrorCode('OTHER'), isNull);
  });

  test('CampusStudent with history; email-verified is flagged', () {
    final s = CampusStudent.fromJson({
      'id': 's1',
      'name': 'Mim',
      'verified': true,
      'via': 'email',
      'vouches': 0,
      'groups': [
        {'id': 'g', 'name': 'CSE 61 · A', 'role': 'cr'},
      ],
      'vouchBlocked': true,
      'history': [
        {
          'method': 'vouch',
          'actor': {'id': 'a', 'name': 'Tanvir'},
          'at': '2026-10-25T08:00:00Z',
          'revokedAt': '2026-10-26T08:00:00Z',
          'reason': 'not in section',
        },
        {'method': 'admin', 'actor': null, 'at': '2026-10-20T08:00:00Z'},
      ],
      'vouchedBy': [
        {'id': 'a', 'name': 'Tanvir', 'at': '2026-10-25T08:00:00Z'},
      ],
      'confirmedOrVouchedFor': 3,
    });
    expect(s.emailVerified, isTrue);
    expect(s.groups.single.isCr, isTrue);
    expect(s.vouchBlocked, isTrue);
    expect(s.history.first.removed, isTrue);
    expect(s.history.first.actor?.name, 'Tanvir');
    expect(s.history.last.actor, isNull);
    expect(s.history.last.method, VerifiedVia.admin);
    expect(s.vouchedBy.single.at, isNotNull);
    expect(s.confirmedOrVouchedFor, 3);
  });

  test('StudentPage knows if there is more', () {
    expect(const StudentPage([]).hasMore, isFalse);
    expect(const StudentPage([], nextCursor: 'x').hasMore, isTrue);
    expect(const StudentPage([], nextPage: 2).hasMore, isTrue);
  });

  test('CampusInbox, sections, reports and blood', () {
    final i = CampusInbox.fromJson({
      'university': {'id': 'u', 'name': 'Demo University'},
      'waiting': [
        {'id': 's', 'name': 'Mim', 'verified': false},
      ],
      'waitingCount': 7,
      'reports': 2,
      'sectionsWithoutCr': 3,
      'openBlood': 1,
      'recent': [
        {
          'method': 'cr',
          'actor': {'id': 'c', 'name': 'Rafi'},
          'user': {'id': 's', 'name': 'Mim'},
          'at': '2026-10-27T08:00:00Z',
        },
      ],
    });
    expect(i.universityName, 'Demo University');
    expect(i.waitingCount, 7);
    expect(i.waiting.single.name, 'Mim');
    expect(i.recent.single.user?.name, 'Mim');

    final s = CampusSection.fromJson({
      'id': 'sec',
      'name': 'CSE 61 · A',
      'term': 'Fall 2026',
      'members': 50,
      'cr': <Object?>[],
    });
    expect(s.hasCr, isFalse);

    final r = CampusReport.fromJson({
      'kind': 'comment',
      'id': 'c1',
      'issueId': 'i1',
      'excerpt': 'bad',
      'reports': 4,
      'reasons': ['spam', 'abuse'],
      'hidden': true,
    });
    expect(r.kind, ReportKind.comment);
    expect(r.reasons, ['spam', 'abuse']);
    expect(r.copyWith(hidden: false).hidden, isFalse);

    final b = CampusBloodRequest.fromJson({
      'id': 'b',
      'bloodGroup': 'O+',
      'hospital': 'Enam',
      'requester': {'id': 'u', 'name': 'Nusrat', 'email': 'x@y.z'},
    });
    expect(b.requesterName, 'Nusrat');
  });

  test('Feedback models and the draft body', () {
    final f = FeedbackEntry.fromJson({
      'id': 'f1',
      'kind': 'bug',
      'message': 'It crashes',
      'status': 'in_progress',
      'images': [
        {'url': '/a', 'thumbUrl': '/a-t'},
      ],
      'createdAt': '2026-10-27T08:00:00Z',
      'unread': true,
    });
    expect(f.kind, FeedbackKind.bug);
    expect(f.status, FeedbackStatus.inProgress);
    expect(f.status.closed, isFalse);
    expect(FeedbackStatus.parse('wont_do').closed, isTrue);
    expect(f.images.single.thumbUrl, '/a-t');
    expect(f.unread, isTrue);
    expect(f.copyWith(unread: false).unread, isFalse);

    final m = FeedbackMessage.fromJson({
      'id': 'm',
      'fromTeam': true,
      'body': 'Hi',
    });
    expect(m.fromTeam, isTrue);

    final json = const FeedbackDraft(
      kind: FeedbackKind.idea,
      message: '  A dark mode please  ',
      imageIds: ['u1'],
      appVersion: '1.0.2',
      build: 8,
      device: 'Pixel',
      os: 'Android 14',
      locale: 'bn',
    ).toJson();
    expect(json['kind'], 'idea');
    expect(json['message'], 'A dark mode please');
    expect(json['images'], ['u1']);
    expect(json['build'], 8);
    expect(
      const FeedbackDraft(kind: FeedbackKind.bug, message: 'x').toJson(),
      isNot(contains('images')),
    );
  });
}
