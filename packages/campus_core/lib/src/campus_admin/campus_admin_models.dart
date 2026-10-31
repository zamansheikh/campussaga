import '../verification/verification_models.dart';

DateTime? _time(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

Map<String, Object?> _map(Object? v) =>
    v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => [
  for (final i in v is List<Object?> ? v : const <Object?>[])
    if (i is Map<String, Object?>) i,
];

/// A group a student belongs to, as campus admins see it.
class StudentGroup {
  const StudentGroup({
    required this.id,
    required this.name,
    required this.isCr,
  });

  factory StudentGroup.fromJson(Map<String, Object?> json) => StudentGroup(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    isCr: json['role'] == 'cr',
  );

  final String id;
  final String name;
  final bool isCr;
}

/// One line of a student's verification history.
class VerificationEvent {
  const VerificationEvent({
    required this.method,
    this.actor,
    this.user,
    this.at,
    this.revokedAt,
    this.reason = '',
  });

  factory VerificationEvent.fromJson(Map<String, Object?> json) =>
      VerificationEvent(
        method: VerifiedVia.parse(json['method']),
        actor: json['actor'] is Map<String, Object?>
            ? PersonRef.fromJson(_map(json['actor']))
            : null,
        // The inbox's recent list names the student; history items don't.
        user: (json['user'] ?? json['student']) is Map<String, Object?>
            ? PersonRef.fromJson(_map(json['user'] ?? json['student']))
            : null,
        at: _time(json['at'] ?? json['createdAt']),
        revokedAt: _time(json['revokedAt']),
        reason: json['reason'] as String? ?? '',
      );

  final VerifiedVia? method;

  /// Who vouched, confirmed or verified; null when the system did.
  final PersonRef? actor;

  /// Whom it was about (the inbox's recent list).
  final PersonRef? user;
  final DateTime? at;
  final DateTime? revokedAt;
  final String reason;

  bool get removed => revokedAt != null;
}

/// A student of the campus admin's university.
class CampusStudent {
  const CampusStudent({
    required this.card,
    this.verified = false,
    this.via,
    this.vouches = 0,
    this.groups = const [],
    this.vouchBlocked = false,
    this.joinedAt,
    this.history = const [],
    this.vouchedBy = const [],
    this.confirmedOrVouchedFor = 0,
  });

  factory CampusStudent.fromJson(Map<String, Object?> json) => CampusStudent(
    card: StudentCard.fromJson(json),
    verified: json['verified'] as bool? ?? false,
    via: VerifiedVia.parse(json['via']),
    vouches: (json['vouches'] as num?)?.toInt() ?? 0,
    groups: [for (final g in _maps(json['groups'])) StudentGroup.fromJson(g)],
    vouchBlocked: json['vouchBlocked'] as bool? ?? false,
    joinedAt: _time(json['joinedAt']),
    history: [
      for (final h in _maps(json['history'])) VerificationEvent.fromJson(h),
    ],
    vouchedBy: [
      for (final v in _maps(json['vouchedBy'])) PersonRef.fromJson(v),
    ],
    confirmedOrVouchedFor:
        (json['confirmedOrVouchedFor'] as num?)?.toInt() ?? 0,
  );

  final StudentCard card;
  final bool verified;
  final VerifiedVia? via;
  final int vouches;
  final List<StudentGroup> groups;
  final bool vouchBlocked;
  final DateTime? joinedAt;

  // Only on the student page.
  final List<VerificationEvent> history;
  final List<PersonRef> vouchedBy;
  final int confirmedOrVouchedFor;

  String get id => card.id;
  String get name => card.name;

  /// Verified by their university email: only the team can change it.
  bool get emailVerified => verified && via == VerifiedVia.email;
}

/// One page of students.
class StudentPage {
  const StudentPage(this.items, {this.nextCursor, this.nextPage});

  final List<CampusStudent> items;

  /// Cursor paging, if the server uses it.
  final String? nextCursor;

  /// Number paging, if the server uses it.
  final int? nextPage;

  bool get hasMore => nextCursor != null || nextPage != null;
}

enum StudentStatus { unverified, verified, all }

/// `GET /campus-admin/inbox`.
class CampusInbox {
  const CampusInbox({
    required this.universityName,
    this.waiting = const [],
    this.waitingCount = 0,
    this.reports = 0,
    this.sectionsWithoutCr = 0,
    this.openBlood = 0,
    this.recent = const [],
  });

  factory CampusInbox.fromJson(Map<String, Object?> json) => CampusInbox(
    universityName: _map(json['university'])['name'] as String? ?? '',
    waiting: [
      for (final s in _maps(json['waiting'])) CampusStudent.fromJson(s),
    ],
    waitingCount: (json['waitingCount'] as num?)?.toInt() ?? 0,
    reports: (json['reports'] as num?)?.toInt() ?? 0,
    sectionsWithoutCr: (json['sectionsWithoutCr'] as num?)?.toInt() ?? 0,
    openBlood: (json['openBlood'] as num?)?.toInt() ?? 0,
    recent: [
      for (final e in _maps(json['recent'])) VerificationEvent.fromJson(e),
    ],
  );

  final String universityName;
  final List<CampusStudent> waiting;
  final int waitingCount;
  final int reports;
  final int sectionsWithoutCr;
  final int openBlood;
  final List<VerificationEvent> recent;
}

/// A class section (group) of the university.
class CampusSection {
  const CampusSection({
    required this.id,
    required this.name,
    this.term = '',
    this.members = 0,
    this.crs = const [],
    this.lastActivityAt,
  });

  factory CampusSection.fromJson(Map<String, Object?> json) => CampusSection(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    term: json['term'] as String? ?? '',
    members: (json['members'] as num?)?.toInt() ?? 0,
    crs: [for (final c in _maps(json['cr'])) PersonRef.fromJson(c)],
    lastActivityAt: _time(json['lastActivityAt']),
  );

  final String id;
  final String name;
  final String term;
  final int members;
  final List<PersonRef> crs;
  final DateTime? lastActivityAt;

  bool get hasCr => crs.isNotEmpty;
}

/// A transport rep.
class BusRep {
  const BusRep({required this.userId, required this.name});

  factory BusRep.fromJson(Map<String, Object?> json) => BusRep(
    userId: (json['userId'] ?? json['id']) as String? ?? '',
    name: json['name'] as String? ?? '',
  );

  final String userId;
  final String name;
}

enum ReportKind {
  issue,
  comment;

  static ReportKind parse(Object? v) => v == 'comment' ? comment : issue;
}

enum ReportAction { hide, restore, dismiss }

/// A reported post or comment.
class CampusReport {
  const CampusReport({
    required this.kind,
    required this.id,
    required this.issueId,
    this.excerpt = '',
    this.reports = 0,
    this.reasons = const [],
    this.createdAt,
    this.hidden = false,
  });

  factory CampusReport.fromJson(Map<String, Object?> json) => CampusReport(
    kind: ReportKind.parse(json['kind']),
    id: json['id'] as String? ?? '',
    issueId: json['issueId'] as String? ?? '',
    excerpt: json['excerpt'] as String? ?? '',
    reports: (json['reports'] as num?)?.toInt() ?? 0,
    reasons: [
      for (final r in json['reasons'] as List<Object?>? ?? const [])
        if (r is String) r,
    ],
    createdAt: _time(json['createdAt']),
    hidden: json['hidden'] as bool? ?? false,
  );

  final ReportKind kind;
  final String id;

  /// The post (a comment's post, or the post itself).
  final String issueId;
  final String excerpt;
  final int reports;
  final List<String> reasons;
  final DateTime? createdAt;
  final bool hidden;

  CampusReport copyWith({bool? hidden}) => CampusReport(
    kind: kind,
    id: id,
    issueId: issueId,
    excerpt: excerpt,
    reports: reports,
    reasons: reasons,
    createdAt: createdAt,
    hidden: hidden ?? this.hidden,
  );
}

/// An open blood request as campus admins see it.
class CampusBloodRequest {
  const CampusBloodRequest({
    required this.id,
    required this.bloodGroup,
    this.units = 1,
    this.hospital = '',
    this.area = '',
    this.urgent = false,
    this.neededBy,
    this.responses = 0,
    this.requesterName = '',
  });

  factory CampusBloodRequest.fromJson(Map<String, Object?> json) =>
      CampusBloodRequest(
        id: json['id'] as String? ?? '',
        bloodGroup: json['bloodGroup'] as String? ?? '',
        units: (json['units'] as num?)?.toInt() ?? 1,
        hospital: json['hospital'] as String? ?? '',
        area: json['area'] as String? ?? '',
        urgent: json['urgent'] as bool? ?? false,
        neededBy: _time(json['neededBy']),
        responses: (json['responses'] as num?)?.toInt() ?? 0,
        requesterName:
            _map(json['requester'])['name'] as String? ??
            json['contactName'] as String? ??
            '',
      );

  final String id;
  final String bloodGroup;
  final int units;
  final String hospital;
  final String area;
  final bool urgent;
  final DateTime? neededBy;
  final int responses;
  final String requesterName;
}

/// What an escalation is about.
enum EscalationKind { student, section, report, other }
