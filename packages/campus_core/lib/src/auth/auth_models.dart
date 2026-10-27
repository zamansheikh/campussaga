/// A supported university (short form).
class University {
  const University({
    required this.id,
    required this.slug,
    required this.name,
    this.nameBn,
  });

  factory University.fromJson(Map<String, Object?> json) => University(
    id: json['id']! as String,
    slug: json['slug']! as String,
    name: json['name']! as String,
    nameBn: json['nameBn'] as String?,
  );

  final String id;
  final String slug;
  final String name;
  final String? nameBn;

  /// Bangla name when the app is in Bangla and one exists.
  String localName(String languageCode) =>
      languageCode == 'bn' && nameBn != null ? nameBn! : name;
}

/// The signed-in student's own profile.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.university,
    required this.role,
    this.displayName,
    this.department,
    this.batch,
  });

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
    id: json['id']! as String,
    email: json['email']! as String,
    university: University.fromJson(
      json['university']! as Map<String, Object?>,
    ),
    role: json['role']! as String,
    displayName: json['displayName'] as String?,
    department: json['department'] as String?,
    batch: json['batch'] as String?,
  );

  final String id;
  final String email;
  final University university;
  final String role;
  final String? displayName;
  final String? department;
  final String? batch;

  /// Name, department and batch are all filled in.
  bool get isComplete =>
      (displayName?.trim().isNotEmpty ?? false) &&
      (department?.trim().isNotEmpty ?? false) &&
      (batch?.trim().isNotEmpty ?? false);
}

/// Access + refresh token pair.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, Object?> json) => AuthTokens(
    accessToken: json['accessToken']! as String,
    accessTokenExpiresAt: DateTime.parse(
      json['accessTokenExpiresAt']! as String,
    ),
    refreshToken: json['refreshToken']! as String,
    refreshTokenExpiresAt: DateTime.parse(
      json['refreshTokenExpiresAt']! as String,
    ),
  );

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': refreshTokenExpiresAt.toUtc().toIso8601String(),
  };
}

/// Result of a successful sign-in.
class SignInResult {
  const SignInResult({required this.user, required this.isNewUser});

  final UserProfile user;

  /// First sign-in: the app can show onboarding.
  final bool isNewUser;
}

/// Answer to "send me a code".
class CodeSent {
  const CodeSent({
    required this.email,
    required this.university,
    required this.expiresIn,
    required this.resendAfter,
  });

  factory CodeSent.fromJson(Map<String, Object?> json) => CodeSent(
    email: json['email']! as String,
    university: University.fromJson(
      json['university']! as Map<String, Object?>,
    ),
    expiresIn: Duration(seconds: (json['expiresInSeconds']! as num).toInt()),
    resendAfter: Duration(
      seconds: (json['resendAfterSeconds']! as num).toInt(),
    ),
  );

  final String email;
  final University university;
  final Duration expiresIn;
  final Duration resendAfter;
}
