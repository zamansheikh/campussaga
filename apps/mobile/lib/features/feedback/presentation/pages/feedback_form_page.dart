import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/version/app_version.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';
import '../../../verification/presentation/verification_text.dart';
import '../../../voice/data/photo_picker.dart';
import '../../data/device_details.dart';
import '../feedback_text.dart';

/// A screenshot added to the feedback, uploaded as soon as it is added.
class _Shot {
  _Shot(this.key, this.bytes);

  final int key;
  final Uint8List bytes;
  String? uploadId;
  Failure? failure;

  bool get uploading => uploadId == null && failure == null;
}

/// Send a bug report, an idea or other feedback with up to 3 screenshots.
class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _message = TextEditingController();
  FeedbackKind _kind = FeedbackKind.bug;
  final _shots = <_Shot>[];
  int _keys = 0;
  DeviceDetails? _device;
  bool _sending = false;
  bool _tried = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _readDevice();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _readDevice() async {
    final d = await getIt<DeviceDetailsSource>().read();
    if (mounted) setState(() => _device = d);
  }

  String _info(BuildContext context) {
    final v = getIt<AppVersion>();
    final d = _device;
    return [
      'VarsityKotha ${v.version} (${v.build})',
      if (d != null && d.device.isNotEmpty) d.device,
      if (d != null && d.os.isNotEmpty) d.os,
      Localizations.localeOf(context).languageCode,
    ].join(' · ');
  }

  bool get _shortMessage =>
      _message.text.trim().length < FeedbackDraft.minLength;

  Future<void> _addShot() async {
    final l10n = AppLocalizations.of(context);
    final camera = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CsIcons.gallery),
              title: Text(l10n.voiceFromGallery),
              onTap: () => Navigator.of(sheet).pop(false),
            ),
            ListTile(
              leading: const Icon(CsIcons.camera),
              title: Text(l10n.voiceTakePhoto),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    );
    if (camera == null || !mounted) return;
    final picked = await getIt<PhotoPicker>().pick(camera: camera);
    if (picked == null || !mounted) return;
    if (picked.bytes.length > 8 * 1024 * 1024) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorImageTooLarge)));
      return;
    }
    final shot = _Shot(++_keys, picked.bytes);
    setState(() => _shots.add(shot));
    try {
      shot.uploadId = await getIt<FeedbackRepository>().upload(
        picked.bytes,
        filename: picked.filename,
        contentType: picked.contentType,
      );
    } on Failure catch (f) {
      shot.failure = f;
    }
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _tried = true;
      _problem = null;
    });
    if (_shortMessage || _shots.any((s) => s.uploading || s.failure != null)) {
      return;
    }
    setState(() => _sending = true);
    final v = getIt<AppVersion>();
    final d = _device;
    final locale = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await getIt<FeedbackRepository>().send(
        FeedbackDraft(
          kind: _kind,
          message: _message.text,
          imageIds: [for (final s in _shots) s.uploadId!],
          appVersion: v.version,
          build: v.build,
          platform: d?.platform ?? 'android',
          device: d?.device ?? '',
          os: d?.os ?? '',
          locale: locale,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.feedbackSentSnack)));
      router.pop();
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _problem = verificationErrorText(l10n, f));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackSend)),
      body: SafeArea(
        child: CsPage(
          children: [
            Wrap(
              spacing: CsSpace.sm,
              children: [
                for (final k in FeedbackKind.values)
                  ChoiceChip(
                    label: Text(feedbackKindLabel(l10n, k)),
                    selected: _kind == k,
                    onSelected: _sending
                        ? null
                        : (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _message,
              enabled: !_sending,
              minLines: 5,
              maxLines: 10,
              maxLength: FeedbackDraft.maxLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.feedbackMessageLabel,
                hintText: l10n.feedbackMessageHint,
                alignLabelWithHint: true,
                errorText: _tried && _shortMessage
                    ? l10n.feedbackTooShort(FeedbackDraft.minLength)
                    : null,
              ),
            ),
            const SizedBox(height: CsSpace.md),
            Text(
              l10n.feedbackScreenshots(FeedbackDraft.maxImages),
              style: context.text.titleSmall,
            ),
            const SizedBox(height: CsSpace.sm),
            Wrap(
              spacing: CsSpace.sm,
              runSpacing: CsSpace.sm,
              children: [
                for (final s in _shots)
                  _ShotTile(
                    shot: s,
                    onRemove: () => setState(() => _shots.remove(s)),
                  ),
                if (_shots.length < FeedbackDraft.maxImages)
                  Tooltip(
                    message: l10n.feedbackAddScreenshot,
                    child: InkWell(
                      onTap: _sending ? null : _addShot,
                      borderRadius: BorderRadius.circular(CsRadius.sm),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.border),
                          borderRadius: BorderRadius.circular(CsRadius.sm),
                        ),
                        child: Icon(CsIcons.addPhoto, color: cs.primary),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CsIcons.info, size: 16, color: cs.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.feedbackAttached(_info(context)),
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
            if (_problem != null) ...[
              const SizedBox(height: CsSpace.md),
              NoticeBanner(text: _problem!),
            ],
            const SizedBox(height: CsSpace.lg),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.feedbackSendButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShotTile extends StatelessWidget {
  const _ShotTile({required this.shot, required this.onRemove});

  final _Shot shot;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CsRadius.sm),
            child: Image.memory(shot.bytes, fit: BoxFit.cover),
          ),
          if (shot.uploading)
            ClipRRect(
              borderRadius: BorderRadius.circular(CsRadius.sm),
              child: ColoredBox(
                color: cs.background.withValues(alpha: 0.5),
                child: const Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
          if (shot.failure != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(CsRadius.sm),
              child: ColoredBox(
                color: cs.error.withValues(alpha: 0.75),
                child: Icon(CsIcons.error, color: cs.onError),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filledTonal(
              tooltip: AppLocalizations.of(context).voiceRemovePhoto,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              onPressed: onRemove,
              icon: const Icon(CsIcons.close),
            ),
          ),
        ],
      ),
    );
  }
}
