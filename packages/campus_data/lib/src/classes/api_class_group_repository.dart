import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// [ClassGroupRepository] on top of the VarsityKotha API.
class ApiClassGroupRepository implements ClassGroupRepository {
  ApiClassGroupRepository(this._api);

  final ApiClient _api;

  Map<String, Object?> _map(Object? data) => data! as Map<String, Object?>;

  @override
  Future<List<ClassGroup>> myGroups() async {
    final data = _map(await _api.get('/groups'));
    return [
      for (final g in data['groups']! as List<Object?>)
        ClassGroup.fromJson(_map(g)),
    ];
  }

  @override
  Future<ClassGroup> create(GroupDraft draft) async =>
      ClassGroup.fromJson(_map(await _api.post('/groups', draft.toJson())));

  @override
  Future<GroupPreview> preview(String code) async {
    final c = Uri.encodeQueryComponent(_code(code));
    return GroupPreview.fromJson(
      _map(await _api.get('/groups/preview?code=$c')),
    );
  }

  @override
  Future<ClassGroup> join(String code) async => ClassGroup.fromJson(
    _map(await _api.post('/groups/join', {'code': _code(code)})),
  );

  @override
  Future<GroupSearchPage> searchGroups(
    String query, {
    String department = '',
    String batch = '',
    int page = 1,
  }) async {
    final q = Uri(
      queryParameters: {
        'q': query.trim(),
        if (department.trim().isNotEmpty) 'department': department.trim(),
        if (batch.trim().isNotEmpty) 'batch': batch.trim(),
        if (page > 1) 'page': '$page',
      },
    ).query;
    return GroupSearchPage.fromJson(_map(await _api.get('/groups/search?$q')));
  }

  @override
  Future<List<FoundGroup>> similarGroups({
    required String department,
    required String batch,
    String section = '',
  }) async {
    final q = Uri(
      queryParameters: {
        'department': department.trim(),
        'batch': batch.trim(),
        if (section.trim().isNotEmpty) 'section': section.trim(),
      },
    ).query;
    final data = _map(await _api.get('/groups/similar?$q'));
    return [
      for (final g in data['items'] as List<Object?>? ?? const [])
        FoundGroup.fromJson(_map(g)),
    ];
  }

  @override
  Future<RoutinePreview> routinePreview(String groupId, {String? code}) async {
    final c = code == null || code.isEmpty
        ? ''
        : '?code=${Uri.encodeQueryComponent(_code(code))}';
    return RoutinePreview.fromJson(
      _map(await _api.get('/groups/${_id(groupId)}/routine-preview$c')),
    );
  }

  @override
  Future<ClassGroup> joinCourses(
    String groupId,
    Set<String> courses, {
    String? code,
  }) async => ClassGroup.fromJson(
    _map(
      await _api.post('/groups/${_id(groupId)}/join-courses', {
        'courses': courses.toList(),
        if (code != null && code.isNotEmpty) 'code': _code(code),
      }),
    ),
  );

  @override
  Future<ClassGroup> update(String groupId, GroupDraft draft) async =>
      ClassGroup.fromJson(
        _map(await _api.put('/groups/${_id(groupId)}', draft.toJson())),
      );

  @override
  Future<void> delete(String groupId) => _api.delete('/groups/${_id(groupId)}');

  @override
  Future<void> leave(String groupId) =>
      _api.post('/groups/${_id(groupId)}/leave');

  @override
  Future<ClassSlot> addSlot(String groupId, SlotDraft draft) async =>
      ClassSlot.fromJson(
        _map(await _api.post('/groups/${_id(groupId)}/slots', draft.toJson())),
      );

  @override
  Future<ClassSlot> updateSlot(
    String groupId,
    String slotId,
    SlotDraft draft,
  ) async => ClassSlot.fromJson(
    _map(
      await _api.put(
        '/groups/${_id(groupId)}/slots/${_id(slotId)}',
        draft.toJson(),
      ),
    ),
  );

  @override
  Future<void> deleteSlot(String groupId, String slotId) =>
      _api.delete('/groups/${_id(groupId)}/slots/${_id(slotId)}');

  @override
  Future<ClassChange> addChange(String groupId, ChangeDraft draft) async =>
      ClassChange.fromJson(
        _map(
          await _api.post('/groups/${_id(groupId)}/changes', draft.toJson()),
        ),
      );

  @override
  Future<void> deleteChange(String groupId, String changeId) =>
      _api.delete('/groups/${_id(groupId)}/changes/${_id(changeId)}');

  @override
  Future<Assessment> addAssessment(
    String groupId,
    AssessmentDraft draft,
  ) async => Assessment.fromJson(
    _map(
      await _api.post('/groups/${_id(groupId)}/assessments', draft.toJson()),
    ),
  );

  @override
  Future<Assessment> updateAssessment(
    String groupId,
    String assessmentId,
    AssessmentDraft draft,
  ) async => Assessment.fromJson(
    _map(
      await _api.put(
        '/groups/${_id(groupId)}/assessments/${_id(assessmentId)}',
        draft.toJson(),
      ),
    ),
  );

  @override
  Future<void> deleteAssessment(String groupId, String assessmentId) =>
      _api.delete('/groups/${_id(groupId)}/assessments/${_id(assessmentId)}');

  @override
  Future<Announcement> postAnnouncement(
    String groupId,
    String body, {
    bool pinned = false,
  }) async => Announcement.fromJson(
    _map(
      await _api.post('/groups/${_id(groupId)}/announcements', {
        'body': body,
        'pinned': pinned,
      }),
    ),
  );

  @override
  Future<Announcement> setAnnouncementPinned(
    String groupId,
    String announcementId, {
    required bool pinned,
  }) async => Announcement.fromJson(
    _map(
      await _api.patch(
        '/groups/${_id(groupId)}/announcements/${_id(announcementId)}',
        {'pinned': pinned},
      ),
    ),
  );

  @override
  Future<void> deleteAnnouncement(String groupId, String announcementId) => _api
      .delete('/groups/${_id(groupId)}/announcements/${_id(announcementId)}');

  @override
  Future<ClassGroup> setHiddenCourses(
    String groupId,
    Set<String> courses,
  ) async => ClassGroup.fromJson(
    _map(
      await _api.put('/groups/${_id(groupId)}/hidden', {
        'courses': courses.toList(),
      }),
    ),
  );

  @override
  Future<ClassGroup> newSemester(String groupId, String semester) async =>
      ClassGroup.fromJson(
        _map(
          await _api.post('/groups/${_id(groupId)}/new-semester', {
            'semester': semester,
          }),
        ),
      );

  @override
  Future<List<GroupMember>> members(String groupId) async {
    final data = _map(await _api.get('/groups/${_id(groupId)}/members'));
    return [
      for (final m in data['members']! as List<Object?>)
        GroupMember.fromJson(_map(m)),
    ];
  }

  @override
  Future<void> setMemberRole(String groupId, String userId, GroupRole role) =>
      _api.put('/groups/${_id(groupId)}/members/${_id(userId)}', {
        'role': role.name,
      });

  @override
  Future<void> removeMember(String groupId, String userId) =>
      _api.delete('/groups/${_id(groupId)}/members/${_id(userId)}');

  @override
  Future<List<ClassSlot>> personalClasses() async {
    final data = _map(await _api.get('/me/classes'));
    return [
      for (final c in data['classes']! as List<Object?>)
        ClassSlot.fromPersonalJson(_map(c)),
    ];
  }

  @override
  Future<ClassSlot> addPersonal(SlotDraft draft) async =>
      ClassSlot.fromPersonalJson(
        _map(await _api.post('/me/classes', draft.toPersonalJson())),
      );

  @override
  Future<ClassSlot> updatePersonal(String id, SlotDraft draft) async =>
      ClassSlot.fromPersonalJson(
        _map(await _api.put('/me/classes/${_id(id)}', draft.toPersonalJson())),
      );

  @override
  Future<void> deletePersonal(String id) =>
      _api.delete('/me/classes/${_id(id)}');

  static String _code(String code) => code.trim().toUpperCase();

  // Ids go into the URL path: never let one carry a slash or query.
  static String _id(String id) => Uri.encodeComponent(id);
}
