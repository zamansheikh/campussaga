import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_form_cubit.dart';
import '../widgets/profile_form.dart';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CsSpace.lg),
            child: ProfileForm(
              initial: user,
              onSaved: (u) {
                context.read<AuthBloc>().add(AuthProfileUpdated(u));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
                context.pop(); // go_router's pop, not Navigator's
              },
            ),
          ),
        ),
      ),
    );
  }
}
