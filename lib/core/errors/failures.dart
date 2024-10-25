// lib/core/errors/failures.dart

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = "Server Failure"]) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = "Cache Failure"]) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = "Authentication Failure"])
      : super(message);
}
