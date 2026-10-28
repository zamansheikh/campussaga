/// A supported university (short form).
class University {
  const University({
    required this.id,
    required this.slug,
    required this.name,
    this.nameBn,
    this.city,
    this.domains = const [],
  });

  factory University.fromJson(Map<String, Object?> json) => University(
    id: json['id']! as String,
    slug: json['slug']! as String,
    name: json['name']! as String,
    nameBn: json['nameBn'] as String?,
    city: json['city'] as String?,
    domains: [
      for (final d in (json['domains'] as List<Object?>?) ?? const [])
        if (d is String) d,
    ],
  );

  final String id;
  final String slug;
  final String name;
  final String? nameBn;
  final String? city;

  /// Student email domains, e.g. `diu.edu.bd`.
  final List<String> domains;

  /// Bangla name when the app is in Bangla and one exists.
  String localName(String languageCode) =>
      languageCode == 'bn' && nameBn != null ? nameBn! : name;

  static const _minorWords = {'of', 'and', 'the', 'for', 'in', 'at', '&'};

  /// The short name students use: initials of the main words, keeping
  /// all-caps words whole ("Daffodil International University" → DIU,
  /// "BRAC University" → BRACU, "American International
  /// University-Bangladesh" → AIUB).
  String get shortName {
    final words = name
        .split(RegExp(r'[\s\-–,()]+'))
        .where((w) => w.isNotEmpty && !_minorWords.contains(w.toLowerCase()));
    final out = StringBuffer();
    for (final w in words) {
      final letters = w.replaceAll(RegExp('[^A-Za-z]'), '');
      if (letters.isEmpty) continue;
      out.write(
        letters.length > 1 && letters == letters.toUpperCase()
            ? letters
            : letters[0].toUpperCase(),
      );
    }
    return out.isEmpty ? slug.toUpperCase() : out.toString();
  }

  static const _domainEndings = {
    'edu',
    'ac',
    'bd',
    'gov',
    'org',
    'com',
    'net',
    'info',
  };

  /// The part of an email domain that names the university:
  /// cs.du.ac.bd → du, juniv.edu → juniv.
  static String _orgLabel(String domain) => domain
      .toLowerCase()
      .split('.')
      .lastWhere((l) => !_domainEndings.contains(l), orElse: () => '');

  /// The university's own email domain, not a department's
  /// (du.ac.bd, not cs.du.ac.bd).
  String? get mainDomain => domains.isEmpty
      ? null
      : (domains.toList()..sort(
              (a, b) =>
                  '.'.allMatches(a).length.compareTo('.'.allMatches(b).length),
            ))
            .first;

  /// Up to about 5 letters for a badge: the short name, or the email
  /// domain's name part when that is the familiar one (du.ac.bd → DU,
  /// hstu.ac.bd → HSTU).
  String get badge {
    final short = shortName;
    final main = mainDomain;
    final label = main == null ? '' : _orgLabel(main);
    final plain = RegExp(r'^[a-z]+$').hasMatch(label);
    if (!plain || label.startsWith(short.toLowerCase())) return short;
    if (label.length <= 4) return label.toUpperCase();
    if (short.length <= 5) return short;
    if (label.length <= 6) return label.toUpperCase();
    return short;
  }

  /// How well [query] finds this university: 0 = no match, higher is better.
  /// Matches the name (English or Bangla), short name, email domain, slug
  /// and city. Two letters only match whole short names and word starts
  /// ("du" doesn't find every ".edu").
  int searchScore(String query) {
    final raw = query.trim();
    final q = raw.toLowerCase();
    if (q.isEmpty) return 1;
    final short = shortName.toLowerCase();
    final badge = this.badge.toLowerCase();
    final labels = {for (final d in domains) _orgLabel(d)}..remove('');
    final n = name.toLowerCase();
    if (badge == q || slug == q || labels.contains(q)) return 6;
    if (short == q) return 5;
    if (n.startsWith(q) || (nameBn?.startsWith(raw) ?? false)) return 4;
    if (short.startsWith(q) ||
        badge.startsWith(q) ||
        labels.any((l) => l.startsWith(q)) ||
        n.split(RegExp(r'[\s\-,()]+')).any((w) => w.startsWith(q)) ||
        (nameBn?.split(' ').any((w) => w.startsWith(raw)) ?? false)) {
      return 3;
    }
    if (q.length >= 3 &&
        (n.contains(q) ||
            (nameBn?.contains(raw) ?? false) ||
            labels.any((l) => l.contains(q)))) {
      return 2;
    }
    if ((city ?? '').toLowerCase().startsWith(q)) return 1;
    return 0;
  }
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
    this.verified = false,
    this.universityEmail,
    this.photoVersion,
    this.googlePhotoUrl,
  });

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
    id: json['id']! as String,
    email: json['email']! as String,
    university: json['university'] == null
        ? null
        : University.fromJson(json['university']! as Map<String, Object?>),
    role: json['role']! as String,
    displayName: json['displayName'] as String?,
    department: json['department'] as String?,
    batch: json['batch'] as String?,
    // Older servers didn't send it: everyone was verified then.
    verified: json['verified'] as bool? ?? true,
    universityEmail: json['universityEmail'] as String?,
    photoVersion: json['photoVersion'] as String?,
    googlePhotoUrl: json['googlePhotoUrl'] as String?,
  );

  final String id;

  /// The sign-in email (a university email, or a personal Google account).
  final String email;

  /// Null until a not-verified student picks their university.
  final University? university;

  /// Proved a university email (signing in with one, or verifying later).
  /// Students of universities without email sign in with Gmail and are
  /// not verified.
  final bool verified;
  final String? universityEmail;
  final String role;
  final String? displayName;
  final String? department;
  final String? batch;

  /// Set when the student uploaded a profile photo (changes with each one).
  final String? photoVersion;

  /// The Google account photo (signed in with Google), shown when there's
  /// no uploaded photo.
  final String? googlePhotoUrl;

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
