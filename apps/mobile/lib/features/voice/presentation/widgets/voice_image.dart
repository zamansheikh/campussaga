import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/di.dart';

/// An issue photo, loaded with the student's sign-in (photos follow their
/// issue's privacy rules on the server). Recent ones stay in memory.
class VoiceImage extends StatefulWidget {
  const VoiceImage(this.imageId, {super.key, this.thumb = true, this.fit});

  final String imageId;
  final bool thumb;
  final BoxFit? fit;

  static final _cache = <String, Uint8List>{};
  static const _keep = 60;

  static void _remember(String key, Uint8List bytes) {
    _cache
      ..remove(key)
      ..[key] = bytes;
    while (_cache.length > _keep) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Forget everything (signed out).
  static void clear() => _cache.clear();

  @override
  State<VoiceImage> createState() => _VoiceImageState();
}

class _VoiceImageState extends State<VoiceImage> {
  late Future<Uint8List> _bytes = _load();

  String get _key => '${widget.imageId}/${widget.thumb ? 't' : 'f'}';

  Future<Uint8List> _load() async {
    final hit = VoiceImage._cache[_key];
    if (hit != null) return hit;
    final bytes = await getIt<VoiceRepository>().image(
      widget.imageId,
      thumb: widget.thumb,
    );
    VoiceImage._remember(_key, bytes);
    return bytes;
  }

  @override
  void didUpdateWidget(VoiceImage old) {
    super.didUpdateWidget(old);
    if (old.imageId != widget.imageId || old.thumb != widget.thumb) {
      _bytes = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: widget.fit ?? BoxFit.cover,
            gaplessPlayback: true,
            // Placeholder until decoded (slow phones, big photos).
            frameBuilder: (_, child, frame, sync) =>
                sync || frame != null ? child : _placeholder(cs, broken: false),
            errorBuilder: (_, _, _) => _placeholder(cs, broken: true),
          );
        }
        return _placeholder(cs, broken: snap.hasError);
      },
    );
  }

  Widget _placeholder(CsColors cs, {required bool broken}) => ColoredBox(
    color: cs.surfaceVariant,
    child: Center(
      child: Icon(
        broken ? Icons.broken_image_outlined : Icons.image_outlined,
        color: cs.textSecondary,
      ),
    ),
  );
}

/// Photos full screen, swipe between them, pinch to zoom.
Future<void> showPhotoViewer(
  BuildContext context,
  List<IssueImage> images,
  int start,
) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: PageView.builder(
          controller: PageController(initialPage: start),
          itemCount: images.length,
          itemBuilder: (context, i) => Semantics(
            image: true,
            label: l10n.voicePhoto(i + 1),
            child: InteractiveViewer(
              child: Center(
                child: VoiceImage(
                  images[i].id,
                  thumb: false,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    },
  ),
);
