import '../classes/class_models.dart';
import 'verification_models.dart';

/// Verification by people (docs/CAMPUS_ADMINS.md §3, students). Every
/// method throws a `Failure`.
abstract interface class VerificationRepository {
  /// Where the signed-in student stands and how to get verified.
  Future<MyVerification> mine();

  /// The student behind a vouch link.
  Future<VouchCard> vouchCard(String code);

  /// Vouch for them (`VOUCH_SELF`, `VERIFY_YOURSELF_FIRST`,
  /// `OTHER_UNIVERSITY`, `VOUCH_BLOCKED`, `VOUCH_LIMIT`,
  /// `ALREADY_VERIFIED`).
  Future<VouchCard> vouch(String code);

  /// A CR confirms a group member (`NOT_CR`, `CONFIRM_LIMIT`, ...).
  Future<GroupMember> confirmMember(String groupId, String userId);

  /// "My university email isn't recognized": no sign-in needed. Give the
  /// picked university or its name.
  Future<void> requestUniversity({
    required String email,
    String? universityId,
    String? universityName,
  });
}
