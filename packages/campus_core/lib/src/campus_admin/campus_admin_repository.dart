import 'campus_admin_models.dart';

/// What a campus admin does for their own university (docs/CAMPUS_ADMINS.md
/// §3). Every method throws a `Failure`; `NOT_CAMPUS_ADMIN` (403) when the
/// caller isn't one.
abstract interface class CampusAdminRepository {
  Future<CampusInbox> inbox();

  /// A page of students: [status], search [query], and (to list a
  /// section's students) [groupId]. Give [cursor] or [page] from the
  /// previous page.
  Future<StudentPage> students({
    StudentStatus status = StudentStatus.unverified,
    String query = '',
    String? groupId,
    String? cursor,
    int? page,
  });

  /// A student with history and who vouched.
  Future<CampusStudent> student(String id);

  Future<CampusStudent> verify(String id);

  /// `EMAIL_VERIFIED` (409) for email-proven students.
  Future<CampusStudent> unverify(String id, String reason);

  Future<CampusStudent> blockVouching(String id, String reason);

  Future<CampusStudent> unblockVouching(String id);

  Future<List<CampusSection>> sections();

  Future<void> makeCr(String sectionId, String userId);

  Future<void> removeCr(String sectionId, String userId);

  Future<List<BusRep>> busReps();

  Future<List<BusRep>> addBusRep(String userId);

  Future<void> removeBusRep(String userId);

  Future<List<CampusReport>> reports();

  Future<void> report(ReportKind kind, String id, ReportAction action);

  Future<List<CampusBloodRequest>> blood();

  Future<void> closeBlood(String id, {String reason = ''});

  /// "Ask the VarsityKotha team".
  Future<void> escalate(EscalationKind kind, String note, {String? targetId});
}
