import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// [ClassGroupRepository] on top of the Campus Saga API.
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

  static String _code(String code) => code.trim().toUpperCase();

  // Ids go into the URL path: never let one carry a slash or query.
  static String _id(String id) => Uri.encodeComponent(id);
}
