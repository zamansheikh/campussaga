import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/routine_cache.dart';

part 'my_classes_state.dart';

/// Keeps the student's groups and routine: the saved copy first, then the
/// server's. App-wide (Today, Routine and the group pages share it).
///
/// Changes (create, join, edit) call the server, then update the state and
/// the saved copy. They throw the server's `Failure` for the page to show.
class MyClassesCubit extends Cubit<MyClassesState> {
  MyClassesCubit(this._repo, this._cache) : super(const MyClassesState());

  final ClassGroupRepository _repo;
  final RoutineCache _cache;

  /// A student signed in (or the app started signed in).
  Future<void> start(String userId) async {
    if (state.userId == userId && state.loaded) return;
    emit(MyClassesState(userId: userId));
    final saved = await _cache.read(userId);
    if (isClosed || state.userId != userId) return;
    if (saved != null) {
      emit(
        state.copyWith(
          groups: saved.groups,
          personal: saved.personal,
          loaded: true,
        ),
      );
    }
    await refresh();
  }

  /// Signed out: forget everything, on the phone too.
  Future<void> clear() async {
    emit(const MyClassesState());
    await _cache.clear();
  }

  /// Fetches the latest from the server. Offline keeps the saved routine.
  Future<void> refresh() async {
    final userId = state.userId;
    if (userId == null || state.refreshing) return;
    emit(state.copyWith(refreshing: true));
    try {
      final (groups, personal) = await (
        _repo.myGroups(),
        _repo.personalClasses(),
      ).wait;
      if (isClosed || state.userId != userId) return;
      _set(groups, personal: personal);
    } on ParallelWaitError<
      (List<ClassGroup>?, List<ClassSlot>?),
      (AsyncError?, AsyncError?)
    > catch (e) {
      if (isClosed || state.userId != userId) return;
      final f = e.errors.$1?.error ?? e.errors.$2?.error;
      emit(
        state.copyWith(
          refreshing: false,
          loaded: true,
          failure: () => f is Failure ? f : const UnexpectedFailure(),
        ),
      );
    } on Failure catch (f) {
      if (isClosed || state.userId != userId) return;
      emit(state.copyWith(refreshing: false, loaded: true, failure: () => f));
    }
  }

  Future<ClassGroup> create(GroupDraft draft) async {
    final g = await _repo.create(draft);
    _set([...state.groups, g]);
    return g;
  }

  Future<GroupPreview> preview(String code) => _repo.preview(code);

  Future<ClassGroup> join(String code) async {
    final g = await _repo.join(code);
    _set([...state.groups.where((x) => x.id != g.id), g]);
    return g;
  }

  Future<void> updateGroup(String id, GroupDraft draft) async {
    final g = await _repo.update(id, draft);
    _replace(g);
  }

  Future<void> leave(String id) async {
    await _repo.leave(id);
    _set(state.groups.where((g) => g.id != id).toList());
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _set(state.groups.where((g) => g.id != id).toList());
  }

  Future<void> addSlot(String groupId, SlotDraft draft) async {
    if (groupId == personalGroupId) {
      final p = await _repo.addPersonal(draft);
      _setPersonal([...state.personal, p]);
      return;
    }
    final s = await _repo.addSlot(groupId, draft);
    final g = state.group(groupId);
    if (g != null) _replace(g.copyWith(slots: _sorted([...g.slots, s])));
  }

  Future<void> updateSlot(
    String groupId,
    String slotId,
    SlotDraft draft,
  ) async {
    final s = await _repo.updateSlot(groupId, slotId, draft);
    final g = state.group(groupId);
    if (g != null) {
      _replace(
        g.copyWith(
          slots: _sorted([for (final x in g.slots) x.id == slotId ? s : x]),
        ),
      );
    }
  }

  Future<void> deleteSlot(String groupId, String slotId) async {
    if (groupId == personalGroupId) {
      await _repo.deletePersonal(slotId);
      _setPersonal(state.personal.where((x) => x.id != slotId).toList());
      return;
    }
    await _repo.deleteSlot(groupId, slotId);
    final g = state.group(groupId);
    if (g != null) {
      _replace(
        g.copyWith(slots: g.slots.where((x) => x.id != slotId).toList()),
      );
    }
  }

  Future<void> addChange(String groupId, ChangeDraft draft) async {
    final c = await _repo.addChange(groupId, draft);
    final g = state.group(groupId);
    if (g == null) return;
    // A new change for a class on a date replaces the old one.
    final kept = g.changes.where(
      (x) => c.slotId == null || !(x.slotId == c.slotId && x.date == c.date),
    );
    _replace(
      g.copyWith(
        changes: [...kept, c]..sort((a, b) => a.date.compareTo(b.date)),
      ),
    );
  }

  Future<void> deleteChange(String groupId, String changeId) async {
    await _repo.deleteChange(groupId, changeId);
    final g = state.group(groupId);
    if (g != null) {
      _replace(
        g.copyWith(changes: g.changes.where((x) => x.id != changeId).toList()),
      );
    }
  }

  Future<void> postAnnouncement(
    String groupId,
    String body, {
    bool pinned = false,
  }) async {
    final a = await _repo.postAnnouncement(groupId, body, pinned: pinned);
    final g = state.group(groupId);
    if (g == null) return;
    _replace(
      g.copyWith(
        announcements: sortAnnouncements([
          for (final x in g.announcements)
            pinned ? x.copyWith(pinned: false) : x,
          a,
        ]),
      ),
    );
  }

  Future<void> setAnnouncementPinned(
    String groupId,
    String id, {
    required bool pinned,
  }) async {
    await _repo.setAnnouncementPinned(groupId, id, pinned: pinned);
    final g = state.group(groupId);
    if (g == null) return;
    _replace(
      g.copyWith(
        announcements: sortAnnouncements([
          for (final x in g.announcements)
            x.id == id
                ? x.copyWith(pinned: pinned)
                : (pinned ? x.copyWith(pinned: false) : x),
        ]),
      ),
    );
  }

  Future<void> deleteAnnouncement(String groupId, String id) async {
    await _repo.deleteAnnouncement(groupId, id);
    final g = state.group(groupId);
    if (g != null) {
      _replace(
        g.copyWith(
          announcements: g.announcements.where((x) => x.id != id).toList(),
        ),
      );
    }
  }

  Future<void> setHiddenCourses(String groupId, Set<String> courses) async =>
      _replace(await _repo.setHiddenCourses(groupId, courses));

  Future<void> newSemester(String groupId, String semester) async =>
      _replace(await _repo.newSemester(groupId, semester));

  Future<List<GroupMember>> members(String groupId) => _repo.members(groupId);

  /// Changing roles (incl. stepping down yourself): fetch the group again.
  Future<void> setMemberRole(
    String groupId,
    String userId,
    GroupRole role,
  ) async {
    await _repo.setMemberRole(groupId, userId, role);
    await refresh();
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _repo.removeMember(groupId, userId);
    final g = state.group(groupId);
    if (g != null) _replace(g.copyWith(memberCount: g.memberCount - 1));
  }

  void _setPersonal(List<ClassSlot> personal) =>
      _set(state.groups, personal: _sorted(personal));

  void _replace(ClassGroup g) =>
      _set([for (final x in state.groups) x.id == g.id ? g : x]);

  void _set(List<ClassGroup> groups, {List<ClassSlot>? personal}) {
    emit(
      state.copyWith(
        groups: groups,
        personal: personal,
        loaded: true,
        refreshing: false,
        failure: () => null,
      ),
    );
    final userId = state.userId;
    if (userId != null) {
      unawaited(
        _cache.write(userId, (groups: groups, personal: state.personal)),
      );
    }
  }

  static List<ClassSlot> _sorted(List<ClassSlot> slots) => slots
    ..sort((a, b) {
      final d = a.weekday.compareTo(b.weekday);
      if (d != 0) return d;
      final t = a.startMin.compareTo(b.startMin);
      return t != 0 ? t : a.courseCode.compareTo(b.courseCode);
    });
}
