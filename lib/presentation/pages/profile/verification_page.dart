import 'dart:io';
import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/domain/entities/user.dart';
import 'package:campussaga/domain/entities/varification_status.dart';
import 'package:campussaga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campussaga/presentation/bloc/auth/auth_state.dart';
import 'package:campussaga/presentation/bloc/varify/varification_bloc.dart';
import 'package:campussaga/presentation/pages/profile/update_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class VerificationPage extends StatefulWidget {
  final User user;
  const VerificationPage({Key? key, required this.user}) : super(key: key);

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  XFile? selfieImage;
  XFile? idCardImage;
  final ImagePicker _picker = ImagePicker();
  File? selfieFile;
  File? idCardFile;

  Future<void> _takeSelfie() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        selfieImage = image;
        selfieFile = File(image.path);
      });
    }
  }

  Future<void> _takeIdCardPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        idCardImage = image;
        idCardFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated
            ? authState.user
            : widget.user;
        return Scaffold(
          // ── AppBar ──────────────────────────────────────────────
          appBar: AppBar(
            forceMaterialTransparency: true,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.shield_tick,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Verify Account',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Take a clear selfie and a photo of your student ID card to verify your account.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Upload row ──────────────────────────────────
                Row(
                  children: [
                    // Selfie
                    Expanded(
                      child: _UploadCard(
                        label: 'Selfie',
                        icon: Iconsax.camera,
                        hint: 'Tap to take selfie',
                        file: selfieFile,
                        isCircle: true,
                        onTap: _takeSelfie,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ID Card
                    Expanded(
                      flex: 2,
                      child: _UploadCard(
                        label: 'University ID Card',
                        icon: Iconsax.card,
                        hint: 'Tap to photograph your ID',
                        file: idCardFile,
                        isCircle: false,
                        onTap: _takeIdCardPhoto,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Personal info card ──────────────────────────
                _buildInfoCard(user, isDark),
              ],
            ),
          ),

          // ── Submit button ────────────────────────────────────
          bottomNavigationBar:
              BlocConsumer<VarificationBloc, VarificationState>(
                listener: (context, state) {
                  if (state is VarificationSuccess) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Verification submitted! We will review soon.',
                        ),
                      ),
                    );
                  } else if (state is VarificationError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
                  }
                },
                builder: (context, state) {
                  final isLoading = state is VarificationInProgress;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1D2024) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () => _submit(user, context),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.shield_tick, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Submit Verification',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
        );
      },
    );
  }

  // ── Info card ────────────────────────────────────────────────────────────────

  Widget _buildInfoCard(User user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.user,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Personal Information',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Iconsax.user, 'Full Name', value: user.name),
          _infoRow(Iconsax.sms, 'Email', value: user.email),
          _infoRow(
            Iconsax.call,
            'Phone',
            value: user.phoneNumber,
            missing: user.phoneNumber == null || user.phoneNumber!.isEmpty,
          ),
          _infoRow(
            Iconsax.calendar,
            'Date of Birth',
            value: user.dateOfBirth != null
                ? '${user.dateOfBirth!.year}-${user.dateOfBirth!.month.toString().padLeft(2, '0')}-${user.dateOfBirth!.day.toString().padLeft(2, '0')}'
                : null,
            missing: user.dateOfBirth == null,
          ),
          _infoRow(
            Iconsax.building,
            'Department',
            value: user.department != null
                ? user.department.toString().split('.').last.toUpperCase()
                : null,
            missing: user.department == null,
          ),
          _infoRow(
            Iconsax.profile_2user,
            'Gender',
            value: user.gender,
            missing: user.gender == null || user.gender!.isEmpty,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UpdateProfilePage(user: user)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.edit_2, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Update missing details',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label, {
    String? value,
    bool missing = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: missing
                ? _missingChip()
                : Text(
                    value ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _missingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      child: Text(
        'Missing',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.orange.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Validation + submit ───────────────────────────────────────────────────────

  void _submit(User user, BuildContext context) {
    final missing = <String>[];
    if (selfieFile == null) missing.add('Selfie photo');
    if (idCardFile == null) missing.add('ID card photo');
    if (user.phoneNumber == null || user.phoneNumber!.isEmpty)
      missing.add('Phone number');
    if (user.dateOfBirth == null) missing.add('Date of birth');
    if (user.department == null) missing.add('Department');
    if (user.gender == null || user.gender!.isEmpty) missing.add('Gender');

    if (missing.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Incomplete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please provide:', style: GoogleFonts.poppins(fontSize: 13)),
              const SizedBox(height: 8),
              ...missing.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.close_circle,
                        size: 13,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateProfilePage(user: user),
                  ),
                );
              },
              child: Text(
                'Update Profile',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final verificationEntity = Verification(
      userUuid: user.id,
      universityEmail: user.email,
      profilePhotoUrl: '',
      universityIdCardPhotoUrl: '',
      status: VerificationStatus.pending,
      phoneNumber: user.phoneNumber ?? '',
      dateOfBirth: user.dateOfBirth ?? DateTime.now(),
      department: user.department.toString(),
      gender: user.gender ?? '',
      timestamp: DateTime.now(),
    );
    context.read<VarificationBloc>().add(
      SubmitVerification(
        verification: verificationEntity,
        files: [selfieFile!, idCardFile!],
      ),
    );
  }
}

// ── Upload card widget ─────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final File? file;
  final bool isCircle;
  final VoidCallback onTap;

  const _UploadCard({
    required this.label,
    required this.icon,
    required this.hint,
    required this.file,
    required this.isCircle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isCircle ? 140 : 140,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2024) : Colors.white,
          borderRadius: BorderRadius.circular(isCircle ? 70 : 16),
          border: Border.all(
            color: hasFile
                ? AppColors.primary.withAlpha(140)
                : Theme.of(context).colorScheme.outline.withAlpha(50),
            width: hasFile ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCircle ? 70 : 14),
          child: hasFile
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(file!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black.withAlpha(100),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.refresh,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Retake',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 22, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
