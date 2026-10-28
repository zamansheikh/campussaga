import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../voice/data/photo_picker.dart';
import '../bloc/profile_form_cubit.dart';
import '../widgets/profile_form.dart';
import '../widgets/user_avatar.dart';

/// Edit name, department and batch from the Profile tab.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => ProfileFormCubit(getIt<ProfileRepository>()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.editProfile)),
        body: SafeArea(
          child: CsPage(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.lg,
              CsSpace.md,
              CsSpace.lg,
              CsSpace.lg,
            ),
            children: [
              const _PhotoHeader(),
              const SizedBox(height: CsSpace.sm),
              Text(
                l10n.editProfileHint,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.cs.textSecondary,
                ),
              ),
              const SizedBox(height: CsSpace.lg),
              ProfileForm(
                initial: user,
                onSaved: (u) {
                  context.read<AuthBloc>().add(AuthProfileUpdated(u));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
                  context.pop(); // go_router's pop, not Navigator's
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, remove }

/// The profile photo with "Add a photo" / "Change photo": take one, pick
/// one, or remove it (the Google photo or initials show again).
class _PhotoHeader extends StatefulWidget {
  const _PhotoHeader();

  @override
  State<_PhotoHeader> createState() => _PhotoHeaderState();
}

class _PhotoHeaderState extends State<_PhotoHeader> {
  bool _busy = false;

  Future<void> _change(UserProfile user) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(CsIcons.camera),
            title: Text(l10n.photoTake),
            onTap: () => Navigator.of(sheet).pop(_PhotoAction.camera),
          ),
          ListTile(
            leading: const Icon(CsIcons.gallery),
            title: Text(l10n.photoGallery),
            onTap: () => Navigator.of(sheet).pop(_PhotoAction.gallery),
          ),
          if (user.photoVersion != null)
            ListTile(
              leading: Icon(CsIcons.delete, color: sheet.cs.error),
              title: Text(
                l10n.photoRemove,
                style: TextStyle(color: sheet.cs.error),
              ),
              onTap: () => Navigator.of(sheet).pop(_PhotoAction.remove),
            ),
          const SizedBox(height: CsSpace.sm),
        ],
      ),
    );
    if (action == null || !mounted) return;
    final auth = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final repo = getIt<ProfileRepository>();
    try {
      if (action == _PhotoAction.remove) {
        setState(() => _busy = true);
        auth.add(AuthProfileUpdated(await repo.removePhoto()));
        messenger.showSnackBar(SnackBar(content: Text(l10n.photoRemoved)));
        return;
      }
      final picked = await getIt<PhotoPicker>().pick(
        camera: action == _PhotoAction.camera,
      );
      if (picked == null || !mounted) return;
      setState(() => _busy = true);
      final u = await repo.uploadPhoto(
        picked.bytes,
        filename: picked.filename,
        contentType: picked.contentType,
      );
      if (u.photoVersion != null) {
        UserAvatar.remember(u.id, u.photoVersion!, picked.bytes);
      }
      auth.add(AuthProfileUpdated(u));
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoUpdated)));
    } on Failure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (f.code) {
            'PHOTO_NOT_ALLOWED' => l10n.photoNotAllowed,
            'PHOTO_CHECK_UNAVAILABLE' => l10n.photoCheckDown,
            'IMAGE_TOO_LARGE' => l10n.photoTooLarge,
            'IMAGE_INVALID' => l10n.photoInvalid,
            _ => l10n.photoCheckDown,
          }),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null) return const SizedBox.shrink();
    final has = user.photoVersion != null;
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _busy ? null : () => _change(user),
                child: UserAvatar.of(user, size: 96),
              ),
              if (_busy)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: cs.primary,
                  shape: CircleBorder(
                    side: BorderSide(color: cs.surface, width: 2),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _busy ? null : () => _change(user),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        CsIcons.camera,
                        size: 18,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => _change(user),
          child: Text(has ? l10n.photoChange : l10n.photoAdd),
        ),
        Text(
          [
            if (!has && user.googlePhotoUrl != null) l10n.photoGoogleHint,
            l10n.photoWhoSees,
          ].join(' '),
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
        ),
      ],
    );
  }
}
