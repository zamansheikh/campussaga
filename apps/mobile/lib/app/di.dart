import 'package:campus_core/campus_core.dart';
import 'package:campus_data/campus_data.dart';
import 'package:get_it/get_it.dart';

import '../features/auth/data/google_auth.dart';
import 'env.dart';

/// Service locator for long-lived services (API client, repositories).
/// Blocs are not registered here: they are created where a screen needs
/// them, and get their repositories from [getIt].
final getIt = GetIt.instance;

/// Registers every service. Call once in main(), after Firebase starts.
/// Tests register fakes instead.
void configureDependencies() {
  if (getIt.isRegistered<ApiClient>()) return;
  getIt
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(const ApiConfig(baseUrl: Env.apiBaseUrl)),
      dispose: (client) => client.close(),
    )
    ..registerLazySingleton<TokenStore>(SecureTokenStore.new)
    ..registerLazySingleton<AuthRepository>(
      () => ApiAuthRepository(getIt<ApiClient>(), getIt<TokenStore>()),
    )
    ..registerLazySingleton<GoogleAuth>(FirebaseGoogleAuth.new);
}
