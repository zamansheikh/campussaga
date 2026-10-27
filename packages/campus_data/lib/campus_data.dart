/// Backend implementations of the repository interfaces in campus_core.
///
/// This is the only package that imports supabase_flutter. Replacing the
/// backend later means rewriting this package only.
library;

export 'src/backend.dart' show Backend, BackendConfig;
