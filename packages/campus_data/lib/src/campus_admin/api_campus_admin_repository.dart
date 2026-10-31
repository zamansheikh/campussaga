import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Campus admin tools over HTTP (docs/CAMPUS_ADMINS.md §3).
class ApiCampusAdminRepository implements CampusAdminRepository {
  ApiCampusAdminRepository(this._api);

  final ApiClient _api;

  static const _base = '/campus-admin';

  static Map<String, Object?> _map(Object? v) => v! as Map<String, Object?>;

  static String _seg(String v) => Uri.encodeComponent(v);

  /// A list sent bare, or inside `{items: [...]}`.
  static List<Map<String, Object?>> _list(Object? v) {
    final raw = v is Map<String, Object?> ? v['items'] : v;
    return [
      for (final i in raw is List<Object?> ? raw : const <Object?>[])
        if (i is Map<String, Object?>) i,
    ];
  }

  static String _q(Map<String, String?> q) {
    final clean = {
      for (final e in q.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return clean.isEmpty ? '' : '?${Uri(queryParameters: clean).query}';
  }

  @override
  Future<CampusInbox> inbox() async =>
      CampusInbox.fromJson(_map(await _api.get('$_base/inbox')));

  @override
  Future<StudentPage> students({
    StudentStatus status = StudentStatus.unverified,
    String query = '',
    String? groupId,
    String? cursor,
    int? page,
  }) async {
    final data = await _api.get(
      '$_base/students${_q({'status': status.name, 'q': query.trim(), 'groupId': groupId, 'cursor': cursor, 'page': page?.toString()})}',
    );
    final items = [for (final s in _list(data)) CampusStudent.fromJson(s)];
    if (data is! Map<String, Object?>) return StudentPage(items);
    final next = data['nextCursor'] as String?;
    if (next != null && next.isNotEmpty) {
      return StudentPage(items, nextCursor: next);
    }
    final total = (data['total'] as num?)?.toInt();
    final size = (data['pageSize'] as num?)?.toInt();
    final at = (data['page'] as num?)?.toInt() ?? page ?? 1;
    if (total != null && size != null && at * size < total) {
      return StudentPage(items, nextPage: at + 1);
    }
    return StudentPage(items);
  }

  @override
  Future<CampusStudent> student(String id) async => CampusStudent.fromJson(
    _map(await _api.get('$_base/students/${_seg(id)}')),
  );

  @override
  Future<CampusStudent> verify(String id) async => CampusStudent.fromJson(
    _map(await _api.post('$_base/students/${_seg(id)}/verify')),
  );

  @override
  Future<CampusStudent> unverify(String id, String reason) async =>
      CampusStudent.fromJson(
        _map(
          await _api.post('$_base/students/${_seg(id)}/unverify', {
            'reason': reason.trim(),
          }),
        ),
      );

  @override
  Future<CampusStudent> blockVouching(String id, String reason) async =>
      CampusStudent.fromJson(
        _map(
          await _api.put('$_base/students/${_seg(id)}/vouch-block', {
            'reason': reason.trim(),
          }),
        ),
      );

  @override
  Future<CampusStudent> unblockVouching(String id) async =>
      CampusStudent.fromJson(
        _map(await _api.delete('$_base/students/${_seg(id)}/vouch-block')),
      );

  @override
  Future<List<CampusSection>> sections() async => [
    for (final s in _list(await _api.get('$_base/sections')))
      CampusSection.fromJson(s),
  ];

  @override
  Future<void> makeCr(String sectionId, String userId) async {
    await _api.put('$_base/sections/${_seg(sectionId)}/cr', {'userId': userId});
  }

  @override
  Future<void> removeCr(String sectionId, String userId) async {
    await _api.delete('$_base/sections/${_seg(sectionId)}/cr/${_seg(userId)}');
  }

  @override
  Future<List<BusRep>> busReps() async => [
    for (final r in _list(await _api.get('$_base/bus-reps')))
      BusRep.fromJson(r),
  ];

  @override
  Future<List<BusRep>> addBusRep(String userId) async => [
    for (final r in _list(
      await _api.put('$_base/bus-reps', {'userId': userId}),
    ))
      BusRep.fromJson(r),
  ];

  @override
  Future<void> removeBusRep(String userId) async {
    await _api.delete('$_base/bus-reps/${_seg(userId)}');
  }

  @override
  Future<List<CampusReport>> reports() async => [
    for (final r in _list(await _api.get('$_base/reports')))
      CampusReport.fromJson(r),
  ];

  @override
  Future<void> report(ReportKind kind, String id, ReportAction action) async {
    await _api.post('$_base/reports/${kind.name}/${_seg(id)}', {
      'action': action.name,
    });
  }

  @override
  Future<List<CampusBloodRequest>> blood() async => [
    for (final r in _list(await _api.get('$_base/blood')))
      CampusBloodRequest.fromJson(r),
  ];

  @override
  Future<void> closeBlood(String id, {String reason = ''}) async {
    await _api.post('$_base/blood/${_seg(id)}/close', {
      if (reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  @override
  Future<void> escalate(
    EscalationKind kind,
    String note, {
    String? targetId,
  }) async {
    await _api.post('$_base/escalations', {
      'kind': kind.name,
      'targetId': ?targetId,
      'note': note.trim(),
    });
  }
}
