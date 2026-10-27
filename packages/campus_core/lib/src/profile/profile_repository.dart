import '../auth/auth_models.dart';

/// The signed-in student's own profile. Every method throws a `Failure`.
abstract interface class ProfileRepository {
  /// Saves name, department and batch. An empty string clears a field.
  Future<UserProfile> updateProfile({
    required String displayName,
    required String department,
    required String batch,
  });

  /// Departments other students at the same university have entered,
  /// matching [query] (any case), most used first.
  Future<List<String>> departmentSuggestions(String query);

  /// Every supported university (for a not-verified student to pick).
  Future<List<University>> universities();

  /// A not-verified student picks their university. A verified student
  /// moving to a university without using its email passes
  /// [leaveVerified] and becomes not verified.
  Future<UserProfile> setUniversity(
    String universityId, {
    bool leaveVerified = false,
  });

  /// Sends a code to a university email to verify the student (or, already
  /// verified, to move to that email's university).
  Future<CodeSent> requestVerifyCode(String email);

  /// Checks the code: the student becomes verified at that university.
  Future<UserProfile> verifyUniversityEmail(String email, String code);
}
