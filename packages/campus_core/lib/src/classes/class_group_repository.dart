import 'class_models.dart';

/// Class groups and their routines. Every method throws a `Failure`.
abstract interface class ClassGroupRepository {
  /// The student's groups, each with its full routine.
  Future<List<ClassGroup>> myGroups();

  /// Creates a group; the caller becomes its CR.
  Future<ClassGroup> create(GroupDraft draft);

  /// What [code] leads to, before joining.
  Future<GroupPreview> preview(String code);

  Future<ClassGroup> join(String code);

  Future<ClassGroup> update(String groupId, GroupDraft draft);

  /// Deletes the group for every member (CR only).
  Future<void> delete(String groupId);

  Future<void> leave(String groupId);

  Future<ClassSlot> addSlot(String groupId, SlotDraft draft);

  Future<ClassSlot> updateSlot(String groupId, String slotId, SlotDraft draft);

  Future<void> deleteSlot(String groupId, String slotId);

  /// Cancels or moves a class, or adds an extra one, on one date (CR).
  /// A new change for a class on a date replaces the previous one.
  Future<ClassChange> addChange(String groupId, ChangeDraft draft);

  /// Undoes a change (CR).
  Future<void> deleteChange(String groupId, String changeId);

  /// Posts a message to the group (CR); pinning unpins the previous one.
  Future<Announcement> postAnnouncement(
    String groupId,
    String body, {
    bool pinned = false,
  });

  Future<Announcement> setAnnouncementPinned(
    String groupId,
    String announcementId, {
    required bool pinned,
  });

  Future<void> deleteAnnouncement(String groupId, String announcementId);

  /// Courses the student doesn't take in this group (hidden from their
  /// own routine and reminders only).
  Future<ClassGroup> setHiddenCourses(String groupId, Set<String> courses);

  /// Clears the weekly routine and renames the semester (CR).
  Future<ClassGroup> newSemester(String groupId, String semester);

  /// Names and roles (CR only).
  Future<List<GroupMember>> members(String groupId);

  /// Makes a member a CR or a CR a member again (CR only).
  Future<void> setMemberRole(String groupId, String userId, GroupRole role);

  Future<void> removeMember(String groupId, String userId);

  /// The student's own classes (only they see them).
  Future<List<ClassSlot>> personalClasses();

  Future<ClassSlot> addPersonal(SlotDraft draft);

  Future<ClassSlot> updatePersonal(String id, SlotDraft draft);

  Future<void> deletePersonal(String id);
}
