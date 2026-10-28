import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/di.dart';

/// A student's avatar: their uploaded photo, else their Google photo, else
/// initials. Uploaded photos come from our API (signed in), cached in
/// memory by version, so each one loads once.
class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.photoVersion,
    this.googlePhotoUrl,
    this.size = 48,
  });

  UserAvatar.of(UserProfile u, {Key? key, double size = 48})
    : this(
        key: key,
        userId: u.id,
        name: u.displayName ?? u.email,
        photoVersion: u.photoVersion,
        googlePhotoUrl: u.googlePhotoUrl,
        size: size,
      );

  final String userId;
  final String name;
  final String? photoVersion;
  final String? googlePhotoUrl;
  final double size;

  /// Recently shown uploaded photos, by "userId/version".
  static final _cache = <String, Uint8List>{};

  /// Puts a photo in the cache (right after uploading it).
  static void remember(String userId, String version, Uint8List bytes) {
    _cache['$userId/$version'] = bytes;
    while (_cache.length > 80) {
      _cache.remove(_cache.keys.first);
    }
  }

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Uint8List? _bytes;

  String? get _key => widget.photoVersion == null
      ? null
      : '${widget.userId}/${widget.photoVersion}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(UserAvatar old) {
    super.didUpdateWidget(old);
    if (old.photoVersion != widget.photoVersion ||
        old.userId != widget.userId) {
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    final key = _key;
    if (key == null) return;
    final cached = UserAvatar._cache[key];
    if (cached != null) {
      _bytes = cached;
      return;
    }
    if (!getIt.isRegistered<ProfileRepository>()) return;
    try {
      final b = await getIt<ProfileRepository>().photo(
        widget.userId,
        widget.photoVersion!,
      );
      UserAvatar.remember(widget.userId, widget.photoVersion!, b);
      if (mounted && _key == key) setState(() => _bytes = b);
    } on Object {
      // Offline or gone: initials (or the Google photo) stay.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final google = widget.googlePhotoUrl;
    final ImageProvider? image = bytes != null
        ? MemoryImage(bytes)
        : widget.photoVersion == null && google != null
        ? NetworkImage(google)
        : null;
    return CsAvatar(name: widget.name, size: widget.size, image: image);
  }
}
