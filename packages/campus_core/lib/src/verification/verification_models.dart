import '../classes/class_models.dart';

DateTime? _time(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

Map<String, Object?> _map(Object? v) =>
    v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => [
  for (final i in v is List<Object?> ? v : const <Object?>[])
    if (i is Map<String, Object?>) i,
];

/// A student by id and name (who vouched, who confirmed).
class PersonRef {
  const PersonRef({required this.id, required this.name, this.at});

  factory PersonRef.fromJson(Map<String, Object?> json) => PersonRef(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    at: _time(json['at']),
  );

  final String id;
  final String name;

  /// When they did it (vouch lists), if the server says.
  final DateTime? at;
}

/// A class group's CR, for "Ask your CR".
class GroupCr {
  const GroupCr({
    required this.groupId,
    required this.groupName,
    required this.crId,
    required this.crName,
  });

  factory GroupCr.fromJson(Map<String, Object?> json) => GroupCr(
    groupId: json['groupId'] as String? ?? '',
    groupName: json['groupName'] as String? ?? '',
    crId: json['crId'] as String? ?? '',
    crName: json['crName'] as String? ?? '',
  );

  final String groupId;
  final String groupName;
  final String crId;
  final String crName;
}

/// How a student was verified.
enum VerifiedVia {
  email,
  cr,
  vouch,
  campusAdmin,
  admin;

  static VerifiedVia? parse(Object? v) => switch (v) {
    'email' => email,
    'cr' => cr,
    'vouch' => vouch,
    'campus_admin' => campusAdmin,
    'admin' => admin,
    _ => null,
  };
}

/// `GET /me/verification`: where the student stands and the ways forward.
class MyVerification {
  const MyVerification({
    required this.verified,
    this.via,
    this.emailPossible = false,
    this.vouches = 0,
    this.needed = 2,
    this.vouchedBy = const [],
    this.code = '',
    this.link = '',
    this.crs = const [],
  });

  factory MyVerification.fromJson(Map<String, Object?> json) => MyVerification(
    verified: json['verified'] as bool? ?? false,
    via: VerifiedVia.parse(json['via']),
    emailPossible: json['emailPossible'] as bool? ?? false,
    vouches: (json['vouches'] as num?)?.toInt() ?? 0,
    needed: (json['needed'] as num?)?.toInt() ?? 2,
    vouchedBy: [
      for (final m in _maps(json['vouchedBy'])) PersonRef.fromJson(m),
    ],
    code: json['code'] as String? ?? '',
    link: json['link'] as String? ?? '',
    crs: [for (final m in _maps(json['crs'])) GroupCr.fromJson(m)],
  );

  final bool verified;
  final VerifiedVia? via;

  /// Their university has known email domains: the email code can work.
  final bool emailPossible;
  final int vouches;
  final int needed;
  final List<PersonRef> vouchedBy;
  final String code;

  /// `https://varsitykotha.com/v/{code}`, to share with classmates.
  final String link;
  final List<GroupCr> crs;
}

/// A student as the vouch page and campus admins show them.
class StudentCard {
  const StudentCard({
    required this.id,
    required this.name,
    this.department,
    this.batch,
    this.photoVersion,
    this.googlePhotoUrl,
  });

  factory StudentCard.fromJson(Map<String, Object?> json) => StudentCard(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    department: json['department'] as String?,
    batch: json['batch'] as String?,
    photoVersion: json['photoVersion'] as String?,
    googlePhotoUrl: json['googlePhotoUrl'] as String?,
  );

  final String id;
  final String name;
  final String? department;
  final String? batch;
  final String? photoVersion;
  final String? googlePhotoUrl;

  /// "CSE · 61", skipping what's empty.
  String get classLine =>
      [department, batch].where((v) => v != null && v.isNotEmpty).join(' · ');
}

/// Why someone can't vouch (`reason` of `GET /vouch/{code}`).
enum VouchReason {
  self,
  notVerified,
  otherUniversity,
  blocked,
  limit,
  alreadyVerified;

  static VouchReason? parse(Object? v) => switch (v) {
    'self' => self,
    'not_verified' => notVerified,
    'other_university' => otherUniversity,
    'blocked' => blocked,
    'limit' => limit,
    'already_verified' => alreadyVerified,
    _ => null,
  };

  /// Error code of `POST /vouch/{code}` that means the same.
  static VouchReason? fromErrorCode(String? code) => switch (code) {
    'VOUCH_SELF' => self,
    'VERIFY_YOURSELF_FIRST' => notVerified,
    'OTHER_UNIVERSITY' => otherUniversity,
    'VOUCH_BLOCKED' => blocked,
    'VOUCH_LIMIT' => limit,
    'ALREADY_VERIFIED' => alreadyVerified,
    _ => null,
  };
}

/// `GET /vouch/{code}`: the student asking, and whether I can vouch.
class VouchCard {
  const VouchCard({
    required this.student,
    required this.universityId,
    required this.universityName,
    this.vouches = 0,
    this.needed = 2,
    this.verified = false,
    this.alreadyVouched = false,
    this.canVouch = false,
    this.reason,
  });

  factory VouchCard.fromJson(Map<String, Object?> json) {
    final uni = _map(json['university']);
    return VouchCard(
      student: StudentCard.fromJson(_map(json['student'])),
      universityId: uni['id'] as String? ?? '',
      universityName: uni['name'] as String? ?? '',
      vouches: (json['vouches'] as num?)?.toInt() ?? 0,
      needed: (json['needed'] as num?)?.toInt() ?? 2,
      verified: json['verified'] as bool? ?? false,
      alreadyVouched: json['alreadyVouched'] as bool? ?? false,
      canVouch: json['canVouch'] as bool? ?? false,
      reason: VouchReason.parse(json['reason']),
    );
  }

  final StudentCard student;
  final String universityId;
  final String universityName;
  final int vouches;
  final int needed;

  /// The student is verified now.
  final bool verified;
  final bool alreadyVouched;
  final bool canVouch;
  final VouchReason? reason;

  int get remaining => (needed - vouches).clamp(0, needed);
}

/// What the confirm call returns is a [GroupMember] (kept here so the
/// verification code needs one import).
typedef ConfirmedMember = GroupMember;
