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
}
