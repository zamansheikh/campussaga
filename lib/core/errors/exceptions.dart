// lib/core/errors/exceptions.dart

class ServerException implements Exception {
  final String message;
  ServerException([this.message = "Server Error"]);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = "Cache Error"]);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = "Authentication Error"]);
}
