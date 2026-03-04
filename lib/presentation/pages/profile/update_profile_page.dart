import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campussaga/presentation/bloc/auth/auth_event.dart';
import 'package:campussaga/presentation/bloc/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:campussaga/domain/entities/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class UpdateProfilePage extends StatefulWidget {
  final User user;
  const UpdateProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final addressController = TextEditingController();
  final guardianPhoneController = TextEditingController();
  final skillsController = TextEditingController();
  final interestsController = TextEditingController();
  final cgpaController = TextEditingController();
  final batchController = TextEditingController();
  final semesterController = TextEditingController();

  Department? selectedDepartment;
  String? selectedBloodGroup;
  String? selectedGender;
  DateTime? selectedDateOfBirth;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  /// Normalize a stored gender string to match _genders list (case-insensitive).
  String? _normalizeGender(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    return _genders.firstWhere(
      (g) => g.toLowerCase() == lower,
      orElse: () => _genders.first,
    );
  }

  /// Normalize a stored blood group string to match _bloodGroups list.
  String? _normalizeBloodGroup(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toUpperCase();
    return _bloodGroups.contains(normalized) ? normalized : null;
  }

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    nameController.text = u.name;
    phoneNumberController.text = u.phoneNumber ?? '';
    addressController.text = u.address ?? '';
    guardianPhoneController.text = u.guardianPhone ?? '';
    skillsController.text = u.skills?.join(', ') ?? '';
    interestsController.text = u.interests?.join(', ') ?? '';
    cgpaController.text = u.cgpa?.toString() ?? '';
    batchController.text = u.batch?.toString() ?? '';
    semesterController.text = u.currentSemester ?? '';
    selectedDepartment = u.department;
    selectedBloodGroup = _normalizeBloodGroup(u.bloodGroup);
    selectedGender = _normalizeGender(u.gender);
    selectedDateOfBirth = u.dateOfBirth;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    guardianPhoneController.dispose();
    skillsController.dispose();
    interestsController.dispose();
    cgpaController.dispose();
    batchController.dispose();
    semesterController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDateOfBirth = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final List<String> skills = skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final List<String> interests = interestsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    context.read<AuthBloc>().add(
      AuthUpdateRequested(
        widget.user.copyWith(
          name: nameController.text.trim(),
          phoneNumber: phoneNumberController.text.trim(),
          address: addressController.text.trim(),
          guardianPhone: guardianPhoneController.text.trim(),
          skills: skills.isEmpty ? null : skills,
          interests: interests.isEmpty ? null : interests,
          cgpa: double.tryParse(cgpaController.text.trim()),
          batch: int.tryParse(batchController.text.trim()),
          currentSemester: semesterController.text.trim().isEmpty
              ? null
              : semesterController.text.trim(),
          dateOfBirth: selectedDateOfBirth,
          department: selectedDepartment,
          bloodGroup: selectedBloodGroup,
          gender: selectedGender,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
              child: const Icon(Iconsax.edit_2, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profile updated!', style: GoogleFonts.poppins()),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.poppins()),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.poppins()),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Stack(
            children: [
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    children: [
                      // ── Basic Info ──────────────────────────────
                      _sectionHeader(Iconsax.user, 'Basic Information'),
                      _field(
                        controller: nameController,
                        label: 'Full Name',
                        icon: Iconsax.user,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      _field(
                        controller: phoneNumberController,
                        label: 'Phone Number',
                        icon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                      ),
                      _field(
                        controller: addressController,
                        label: 'Address',
                        icon: Iconsax.location,
                      ),
                      _dropdownField<String>(
                        label: 'Gender',
                        icon: Iconsax.profile_2user,
                        hint: 'Select Gender',
                        value: selectedGender,
                        items: _genders,
                        onChanged: (v) => setState(() => selectedGender = v),
                      ),
                      _bloodGroupDropdown(),
                      _datePickerField(),

                      // ── Academic Info ────────────────────────────
                      const SizedBox(height: 8),
                      _sectionHeader(Iconsax.book_1, 'Academic Information'),
                      _departmentDropdown(isDark),
                      _field(
                        controller: cgpaController,
                        label: 'CGPA',
                        icon: Iconsax.chart_2,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final d = double.tryParse(v);
                          if (d == null) return 'Enter a valid number';
                          if (d < 0 || d > 4.0) return 'CGPA must be 0.0 – 4.0';
                          return null;
                        },
                      ),
                      _field(
                        controller: batchController,
                        label: 'Batch (Year)',
                        icon: Iconsax.calendar,
                        keyboardType: TextInputType.number,
                      ),
                      _field(
                        controller: semesterController,
                        label: 'Current Semester',
                        icon: Iconsax.book_saved,
                      ),

                      // ── Other Info ───────────────────────────────
                      const SizedBox(height: 8),
                      _sectionHeader(Iconsax.heart, 'Skills & Interests'),
                      _field(
                        controller: skillsController,
                        label: 'Skills',
                        icon: Iconsax.star,
                        hint: 'e.g. Flutter, Python, UI Design',
                        maxLines: 2,
                      ),
                      _field(
                        controller: interestsController,
                        label: 'Interests',
                        icon: Iconsax.heart,
                        hint: 'e.g. Gaming, Photography',
                        maxLines: 2,
                      ),
                      _field(
                        controller: guardianPhoneController,
                        label: 'Guardian Phone',
                        icon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Save button ──────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
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
                        disabledBackgroundColor: AppColors.primary.withAlpha(
                          120,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading ? null : _save,
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
                                const Icon(Iconsax.tick_circle, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: AppColors.primary.withAlpha(60),
              thickness: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(fontSize: 13),
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(60),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon, hint: hint),
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required IconData icon,
    required String hint,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        hint: Text(hint, style: GoogleFonts.poppins(fontSize: 13)),
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          );
        }).toList(),
        decoration: _inputDecoration(label, icon),
        isExpanded: true,
      ),
    );
  }

  Widget _bloodGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey(selectedBloodGroup),
        initialValue: selectedBloodGroup,
        hint: Text(
          'Select Blood Group',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        onChanged: (v) => setState(() => selectedBloodGroup = v),
        items: _bloodGroups.map((bg) {
          return DropdownMenuItem<String>(
            value: bg,
            child: Text(bg, style: GoogleFonts.poppins(fontSize: 13)),
          );
        }).toList(),
        decoration: _inputDecoration('Blood Group', Iconsax.health),
        isExpanded: true,
      ),
    );
  }

  Widget _departmentDropdown(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<Department>(
        key: ValueKey(selectedDepartment),
        initialValue: selectedDepartment,
        hint: Text(
          'Select Department',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        onChanged: (v) => setState(() => selectedDepartment = v),
        isExpanded: true,
        menuMaxHeight: 300,
        items: Department.values.map((dept) {
          return DropdownMenuItem<Department>(
            value: dept,
            child: Text(
              dept.toString().split('.').last.toUpperCase(),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          );
        }).toList(),
        decoration: _inputDecoration('Department', Iconsax.building),
      ),
    );
  }

  Widget _datePickerField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickDateOfBirth,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _inputDecoration('Date of Birth', Iconsax.calendar_1),
          child: Text(
            selectedDateOfBirth == null
                ? 'Tap to select'
                : '${selectedDateOfBirth!.year}-'
                      '${selectedDateOfBirth!.month.toString().padLeft(2, '0')}-'
                      '${selectedDateOfBirth!.day.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: selectedDateOfBirth == null
                  ? const Color(0xFF9CA3AF)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
