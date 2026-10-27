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
}
