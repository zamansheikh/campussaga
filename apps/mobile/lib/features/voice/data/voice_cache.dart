import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A post being written, kept on the phone until it is posted. Photos are
/// not kept (too large); the student adds them again.
class VoiceDraft {
  const VoiceDraft({
    this.category,
    this.title = '',
    this.body = '',
    this.place = '',
    this.anonymous = true,
  });

  factory VoiceDraft.fromJson(Map<String, Object?> json) => VoiceDraft(
    category: json['category'] == null
        ? null
        : IssueCategory.parse(json['category'] as String?),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    place: json['place'] as String? ?? '',
    anonymous: json['anonymous'] as bool? ?? true,
  );

  final IssueCategory? category;
  final String title;
  final String body;
  final String place;
  final bool anonymous;

  /// Nothing typed yet (a picked category alone isn't worth restoring).
  bool get isEmpty => title.isEmpty && body.isEmpty && place.isEmpty;

  Map<String, Object?> toJson() => {
    'category': category?.wire,
    'title': title,
    'body': body,
    'place': place,
    'anonymous': anonymous,
  };
}

/// Campus Voice saved on the phone, per account: the last feed page of each
/// order, recently opened issues (to read offline) and the draft.
abstract interface class VoiceCache {
  Future<List<IssueCard>?> feed(String userId, IssueSort sort);
  Future<void> saveFeed(String userId, IssueSort sort, List<IssueCard> items);
  Future<Issue?> issue(String userId, String id);
  Future<void> saveIssue(String userId, Issue issue);
  Future<VoiceDraft?> draft(String userId);
  Future<void> saveDraft(String userId, VoiceDraft draft);
  Future<void> clearDraft();

  /// Signed out: nothing of this account stays.
  Future<void> clear();
}

class PrefsVoiceCache implements VoiceCache {
  PrefsVoiceCache([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _feed = 'voice.feed.';
  static const _issues = 'voice.issues';
  static const _draft = 'voice.draft';

  /// Opened issues kept for offline reading.
  static const keepIssues = 20;

  Future<Map<String, Object?>?> _read(String key, String userId) async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, Object?>;
      return json['userId'] == userId ? json : null;
    } on Object {
      return null; // unreadable (older format): ignore
    }
  }

  @override
  Future<List<IssueCard>?> feed(String userId, IssueSort sort) async {
    final json = await _read('$_feed${sort.wire}', userId);
    if (json == null) return null;
    try {
      return [
        for (final i in json['items']! as List<Object?>)
          IssueCard.fromJson(i! as Map<String, Object?>),
      ];
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveFeed(String userId, IssueSort sort, List<IssueCard> items) =>
      _prefs.setString(
        '$_feed${sort.wire}',
        jsonEncode({
          'userId': userId,
          'items': [for (final c in items) c.toJson()],
        }),
      );

  @override
  Future<Issue?> issue(String userId, String id) async {
    final json = await _read(_issues, userId);
    final list = json?['issues'] as List<Object?>?;
    if (list == null) return null;
    try {
      for (final i in list) {
        final m = i! as Map<String, Object?>;
        if (m['id'] == id) return Issue.fromJson(m);
      }
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Future<void> saveIssue(String userId, Issue issue) async {
    final json = await _read(_issues, userId);
    final kept = [
      issue.toJson(),
      for (final i in json?['issues'] as List<Object?>? ?? const [])
        if (i is Map<String, Object?> && i['id'] != issue.id) i,
    ].take(keepIssues).toList();
    await _prefs.setString(
      _issues,
      jsonEncode({'userId': userId, 'issues': kept}),
    );
  }

  @override
  Future<VoiceDraft?> draft(String userId) async {
    final json = await _read(_draft, userId);
    if (json == null) return null;
    return VoiceDraft.fromJson(json['draft']! as Map<String, Object?>);
  }

  @override
  Future<void> saveDraft(String userId, VoiceDraft draft) => _prefs.setString(
    _draft,
    jsonEncode({'userId': userId, 'draft': draft.toJson()}),
  );

  @override
  Future<void> clearDraft() => _prefs.remove(_draft);

  @override
  Future<void> clear() async {
    for (final s in IssueSort.values) {
      await _prefs.remove('$_feed${s.wire}');
    }
    await _prefs.remove(_issues);
    await _prefs.remove(_draft);
  }
}

/// In memory (tests).
class MemoryVoiceCache implements VoiceCache {
  final feeds = <String, List<IssueCard>>{};
  final issues = <String, Issue>{};
  VoiceDraft? savedDraft;
  String? draftUser;

  @override
  Future<List<IssueCard>?> feed(String userId, IssueSort sort) async =>
      feeds['$userId/${sort.wire}'];

  @override
  Future<void> saveFeed(
    String userId,
    IssueSort sort,
    List<IssueCard> items,
  ) async => feeds['$userId/${sort.wire}'] = items;

  @override
  Future<Issue?> issue(String userId, String id) async => issues['$userId/$id'];

  @override
  Future<void> saveIssue(String userId, Issue issue) async =>
      issues['$userId/${issue.id}'] = issue;

  @override
  Future<VoiceDraft?> draft(String userId) async =>
      draftUser == userId ? savedDraft : null;

  @override
  Future<void> saveDraft(String userId, VoiceDraft draft) async {
    draftUser = userId;
    savedDraft = draft;
  }

  @override
  Future<void> clearDraft() async => savedDraft = null;

  @override
  Future<void> clear() async {
    feeds.clear();
    issues.clear();
    savedDraft = null;
  }
}
