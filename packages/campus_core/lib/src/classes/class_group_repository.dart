import 'assessment_models.dart';
import 'class_models.dart';
import 'discovery_models.dart';

/// Class groups and their routines. Every method throws a `Failure`.
abstract interface class ClassGroupRepository {
  /// The student's groups, each with its full routine.
  Future<List<ClassGroup>> myGroups();

  /// Creates a group; the caller becomes its CR.
  Future<ClassGroup> create(GroupDraft draft);

  /// What [code] leads to, before joining.
  Future<GroupPreview> preview(String code);

  Future<ClassGroup> join(String code);

  /// "Find your class": findable groups of the student's university that
  /// match [query] (department, batch, section, course code, title or
  /// teacher; an exact join code too). Pages start at 1.
  Future<GroupSearchPage> searchGroups(
    String query, {
    String department = '',
    String batch = '',
    int page = 1,
  });

  /// Groups that may already be the one a CR is about to create.
  Future<List<FoundGroup>> similarGroups({
    required String department,
    required String batch,
    String section = '',
  });

  /// A group's weekly routine before joining ([code] for a code-only one).
  Future<RoutinePreview> routinePreview(String groupId, {String? code});

  /// Joins for [courses] only (course codes): the group's other courses are
  /// hidden, and ones added later too. Every course = the whole section. A
  /// member calls it again to change their courses.
  Future<ClassGroup> joinCourses(
    String groupId,
    Set<String> courses, {
    String? code,
  });

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

  /// Adds a test or deadline (any member).
  Future<Assessment> addAssessment(String groupId, AssessmentDraft draft);

  /// Changes one (who added it, or a CR).
  Future<Assessment> updateAssessment(
    String groupId,
    String assessmentId,
    AssessmentDraft draft,
  );

  /// Deletes one (who added it, or a CR).
  Future<void> deleteAssessment(String groupId, String assessmentId);

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

  /// Changes a message's text (CR); classmates aren't notified again.
  Future<Announcement> editAnnouncement(
    String groupId,
    String announcementId,
    String body,
  );

  Future<void> deleteAnnouncement(String groupId, String announcementId);

  /// Courses the student doesn't take in this group (hidden from their
  /// own routine and reminders only).
  Future<ClassGroup> setHiddenCourses(String groupId, Set<String> courses);

  /// Saves a course's extras (CR); all empty removes them.
  Future<ClassGroup> setCourseInfo(
    String groupId,
    String courseCode,
    CourseInfo info,
  );

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
