/// Backend implementations of the repository interfaces in campus_core.
///
/// This is the only package that talks to the Campus Saga API (over HTTP).
/// Replacing the backend later means rewriting this package only.
library;

export 'src/api_client.dart';
export 'src/auth/api_auth_repository.dart';
export 'src/auth/token_store.dart';
export 'src/profile/api_profile_repository.dart';
