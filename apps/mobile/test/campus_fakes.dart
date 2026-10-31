import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';

/// A vouch card for tests: Tanvir asks, 1 of 2 done.
VouchCard sampleVouchCard({
  int vouches = 0,
  bool canVouch = true,
  VouchReason? reason,
  bool verified = false,
  bool alreadyVouched = false,
}) => VouchCard(
  student: const StudentCard(
    id: 'tan',
    name: 'Tanvir Ahmed',
    department: 'CSE',
    batch: '61',
  ),
  universityId: 'uni1',
  universityName: 'Demo University',
  vouches: vouches,
  verified: verified,
  alreadyVouched: alreadyVouched,
  canVouch: canVouch,
  reason: reason,
);

/// In-memory verification by people.
class FakeVerificationRepository implements VerificationRepository {
  MyVerification mineData = const MyVerification(
    verified: false,
    emailPossible: true,
    vouches: 1,
    vouchedBy: [PersonRef(id: 'a', name: 'Nusrat')],
    code: 'abc12345',
    link: 'https://varsitykotha.com/v/abc12345',
    crs: [
      GroupCr(
        groupId: 'g1',
        groupName: 'CSE 61 · A',
        crId: 'cr1',
        crName: 'Rafi',
      ),
    ],
  );
  VouchCard card = sampleVouchCard();
  Failure? failure;

  /// Errors `POST /vouch` answers with (an error code).
  String? vouchError;
  final vouchedCodes = <String>[];
  final confirmed = <(String, String)>[];
  final domainRequests = <(String, String?, String?)>[];

  void _check() {
    if (failure != null) throw failure!;
  }

  @override
  Future<MyVerification> mine() async {
    _check();
    return mineData;
  }

  @override
  Future<VouchCard> vouchCard(String code) async {
    _check();
    return card;
  }

  @override
  Future<VouchCard> vouch(String code) async {
    _check();
    if (vouchError != null) {
      throw RejectedFailure(code: vouchError!);
    }
    vouchedCodes.add(code);
    final n = card.vouches + 1;
    return card = sampleVouchCard(
      vouches: n,
      verified: n >= card.needed,
      alreadyVouched: true,
      canVouch: false,
    );
  }

  @override
  Future<GroupMember> confirmMember(String groupId, String userId) async {
    _check();
    if (vouchError != null) throw RejectedFailure(code: vouchError!);
    confirmed.add((groupId, userId));
    return GroupMember(userId: userId, name: '', role: GroupRole.member);
  }

  @override
  Future<void> requestUniversity({
    required String email,
    String? universityId,
    String? universityName,
  }) async {
    _check();
    domainRequests.add((email, universityId, universityName));
  }
}

CampusStudent sampleStudent({
  String id = 's1',
  String name = 'Mim Akter',
  bool verified = false,
  VerifiedVia? via,
  bool vouchBlocked = false,
  List<StudentGroup> groups = const [
    StudentGroup(id: 'sec1', name: 'CSE 61 · A', isCr: false),
  ],
  List<VerificationEvent> history = const [],
}) => CampusStudent(
  card: StudentCard(id: id, name: name, department: 'CSE', batch: '61'),
  verified: verified,
  via: via,
  vouches: 1,
  groups: groups,
  vouchBlocked: vouchBlocked,
  history: history,
);

/// In-memory campus admin tools.
class FakeCampusAdminRepository implements CampusAdminRepository {
  final students_ = <CampusStudent>[
    sampleStudent(),
    sampleStudent(
      id: 's2',
      name: 'Sadia Rahman',
      verified: true,
      via: VerifiedVia.email,
    ),
    sampleStudent(
      id: 's3',
      name: 'Karim Hasan',
      verified: true,
      via: VerifiedVia.vouch,
    ),
  ];
  var sections_ = <CampusSection>[
    const CampusSection(
      id: 'sec1',
      name: 'CSE 61 · A',
      term: 'Fall 2026',
      members: 52,
    ),
    const CampusSection(
      id: 'sec2',
      name: 'EEE 60 · B',
      members: 40,
      crs: [PersonRef(id: 's9', name: 'Jamal')],
    ),
  ];
  var reports_ = <CampusReport>[
    const CampusReport(
      kind: ReportKind.issue,
      id: 'r1',
      issueId: 'iss1',
      excerpt: 'Selling fake notes, DM me',
      reports: 3,
      reasons: ['spam'],
    ),
  ];
  var blood_ = <CampusBloodRequest>[
    const CampusBloodRequest(
      id: 'b1',
      bloodGroup: 'B+',
      hospital: 'Enam Medical',
      area: 'Savar',
      requesterName: 'Nusrat',
    ),
  ];
  var reps_ = <BusRep>[const BusRep(userId: 'rep1', name: 'Imran')];

  Failure? failure;
  final calls = <String>[];
  final escalations = <(EscalationKind, String, String?)>[];

  void _check() {
    if (failure != null) throw failure!;
  }

  CampusStudent _find(String id) => students_.firstWhere((s) => s.id == id);

  void _put(CampusStudent s) {
    final at = students_.indexWhere((x) => x.id == s.id);
    students_[at] = s;
  }

  @override
  Future<CampusInbox> inbox() async {
    _check();
    final waiting = students_.where((s) => !s.verified).toList();
    return CampusInbox(
      universityName: 'Demo University',
      waiting: waiting,
      waitingCount: waiting.length,
      reports: reports_.length,
      sectionsWithoutCr: sections_.where((s) => !s.hasCr).length,
      openBlood: blood_.length,
      recent: const [
        VerificationEvent(
          method: VerifiedVia.vouch,
          actor: PersonRef(id: 'a', name: 'Tanvir'),
          user: PersonRef(id: 's3', name: 'Karim Hasan'),
        ),
      ],
    );
  }

  @override
  Future<StudentPage> students({
    StudentStatus status = StudentStatus.unverified,
    String query = '',
    String? groupId,
    String? cursor,
    int? page,
  }) async {
    _check();
    calls.add('students:${status.name}:$query');
    return StudentPage([
      for (final s in students_)
        if ((status == StudentStatus.all ||
                (status == StudentStatus.verified) == s.verified) &&
            s.name.toLowerCase().contains(query.trim().toLowerCase()))
          s,
    ]);
  }

  @override
  Future<CampusStudent> student(String id) async {
    _check();
    return _find(id);
  }

  @override
  Future<CampusStudent> verify(String id) async {
    _check();
    calls.add('verify:$id');
    final s = _find(id);
    _put(
      sampleStudent(
        id: s.id,
        name: s.name,
        verified: true,
        via: VerifiedVia.campusAdmin,
        history: const [
          VerificationEvent(
            method: VerifiedVia.campusAdmin,
            actor: PersonRef(id: 'me', name: 'Rafi'),
          ),
        ],
      ),
    );
    return _find(id);
  }

  @override
  Future<CampusStudent> unverify(String id, String reason) async {
    _check();
    final s = _find(id);
    if (s.emailVerified) throw const RejectedFailure(code: 'EMAIL_VERIFIED');
    calls.add('unverify:$id:$reason');
    _put(sampleStudent(id: s.id, name: s.name));
    return _find(id);
  }

  @override
  Future<CampusStudent> blockVouching(String id, String reason) async {
    _check();
    calls.add('block:$id:$reason');
    final s = _find(id);
    _put(
      sampleStudent(
        id: s.id,
        name: s.name,
        verified: s.verified,
        via: s.via,
        vouchBlocked: true,
      ),
    );
    return _find(id);
  }

  @override
  Future<CampusStudent> unblockVouching(String id) async {
    _check();
    calls.add('unblock:$id');
    final s = _find(id);
    _put(
      sampleStudent(id: s.id, name: s.name, verified: s.verified, via: s.via),
    );
    return _find(id);
  }

  @override
  Future<List<CampusSection>> sections() async {
    _check();
    return [...sections_]..sort(
      (a, b) => a.hasCr == b.hasCr
          ? 0
          : a.hasCr
          ? 1
          : -1,
    );
  }

  @override
  Future<void> makeCr(String sectionId, String userId) async {
    _check();
    calls.add('makeCr:$sectionId:$userId');
    final name = _find(userId).name;
    sections_ = [
      for (final s in sections_)
        s.id == sectionId
            ? CampusSection(
                id: s.id,
                name: s.name,
                term: s.term,
                members: s.members,
                crs: [
                  ...s.crs,
                  PersonRef(id: userId, name: name),
                ],
              )
            : s,
    ];
  }

  @override
  Future<void> removeCr(String sectionId, String userId) async {
    _check();
    calls.add('removeCr:$sectionId:$userId');
    sections_ = [
      for (final s in sections_)
        s.id == sectionId
            ? CampusSection(
                id: s.id,
                name: s.name,
                term: s.term,
                members: s.members,
                crs: [
                  for (final c in s.crs)
                    if (c.id != userId) c,
                ],
              )
            : s,
    ];
  }

  @override
  Future<List<BusRep>> busReps() async {
    _check();
    return reps_;
  }

  @override
  Future<List<BusRep>> addBusRep(String userId) async {
    _check();
    calls.add('addRep:$userId');
    reps_ = [...reps_, BusRep(userId: userId, name: _find(userId).name)];
    return reps_;
  }

  @override
  Future<void> removeBusRep(String userId) async {
    _check();
    calls.add('removeRep:$userId');
    reps_ = [
      for (final r in reps_)
        if (r.userId != userId) r,
    ];
  }

  @override
  Future<List<CampusReport>> reports() async {
    _check();
    return reports_;
  }

  @override
  Future<void> report(ReportKind kind, String id, ReportAction action) async {
    _check();
    calls.add('report:${kind.name}:$id:${action.name}');
    reports_ = switch (action) {
      ReportAction.dismiss => [
        for (final r in reports_)
          if (r.id != id) r,
      ],
      _ => [
        for (final r in reports_)
          r.id == id ? r.copyWith(hidden: action == ReportAction.hide) : r,
      ],
    };
  }

  @override
  Future<List<CampusBloodRequest>> blood() async {
    _check();
    return blood_;
  }

  @override
  Future<void> closeBlood(String id, {String reason = ''}) async {
    _check();
    calls.add('closeBlood:$id:$reason');
    blood_ = [
      for (final b in blood_)
        if (b.id != id) b,
    ];
  }

  @override
  Future<void> escalate(
    EscalationKind kind,
    String note, {
    String? targetId,
  }) async {
    _check();
    escalations.add((kind, note, targetId));
  }
}

/// In-memory feedback.
class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository() {
    entries = [];
  }

  late List<FeedbackEntry> entries;
  final threads = <String, List<FeedbackMessage>>{};
  final sent = <FeedbackDraft>[];
  final replies = <(String, String)>[];
  final uploads = <Uint8List>[];
  Failure? failure;
  var _ids = 0;

  /// Team has written to this one.
  void addTeamReply(String id, String body) {
    threads[id] = [
      ...?threads[id],
      FeedbackMessage(id: 'm${++_ids}', fromTeam: true, body: body),
    ];
    entries = [
      for (final e in entries)
        e.id == id
            ? e.copyWith(status: FeedbackStatus.planned, unread: true)
            : e,
    ];
  }

  @override
  Future<FeedbackEntry> send(FeedbackDraft draft) async {
    if (failure != null) throw failure!;
    sent.add(draft);
    final e = FeedbackEntry(
      id: 'f${++_ids}',
      kind: draft.kind,
      message: draft.message.trim(),
      status: FeedbackStatus.fresh,
      createdAt: DateTime(2026, 10, 27, 11),
      lastMessageAt: DateTime(2026, 10, 27, 11),
    );
    entries = [e, ...entries];
    return e;
  }

  @override
  Future<List<FeedbackEntry>> mine() async {
    if (failure != null) throw failure!;
    return entries;
  }

  @override
  Future<FeedbackThread> thread(String id) async {
    if (failure != null) throw failure!;
    final e = entries.firstWhere(
      (x) => x.id == id,
      orElse: () => throw const NotFoundFailure(code: 'FEEDBACK_NOT_FOUND'),
    );
    entries = [
      for (final x in entries) x.id == id ? x.copyWith(unread: false) : x,
    ];
    return FeedbackThread(e, threads[id] ?? const []);
  }

  @override
  Future<FeedbackMessage> reply(String id, String body) async {
    if (failure != null) throw failure!;
    replies.add((id, body));
    final m = FeedbackMessage(
      id: 'm${++_ids}',
      fromTeam: false,
      body: body,
      createdAt: DateTime(2026, 10, 27, 12),
    );
    threads[id] = [...?threads[id], m];
    return m;
  }

  @override
  Future<String> upload(
    Uint8List bytes, {
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    uploads.add(bytes);
    return 'up${uploads.length}';
  }

  @override
  Future<Uint8List> image(String url) async => Uint8List(0);
}
