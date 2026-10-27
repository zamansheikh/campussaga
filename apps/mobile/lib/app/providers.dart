import 'package:campus_data/campus_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';

/// The single API client. Repositories (sign-in, profile, routine) are
/// built on top of it in campus_data.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(const ApiConfig(baseUrl: Env.apiBaseUrl));
  ref.onDispose(client.close);
  return client;
});
