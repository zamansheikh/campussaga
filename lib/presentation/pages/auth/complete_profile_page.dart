import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/domain/entities/university.dart';
import 'package:campussaga/domain/entities/user.dart';
import 'package:campussaga/presentation/bloc/admin/admin_bloc.dart';
import 'package:campussaga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campussaga/presentation/bloc/auth/auth_event.dart';
import 'package:campussaga/presentation/bloc/auth/auth_state.dart';
import 'package:campussaga/presentation/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// ---------------------------------------------------------------------------
// Predefined Bangladeshi universities
// ---------------------------------------------------------------------------
class _BdUniversity {
  final String id;
  final String name;
  final bool isPublic;
  const _BdUniversity(this.id, this.name, {this.isPublic = true});
}

const _bdUniversities = <_BdUniversity>[
  // Public
  _BdUniversity('dhaka-university', 'University of Dhaka'),
  _BdUniversity(
    'buet',
    'Bangladesh University of Engineering and Technology (BUET)',
  ),
  _BdUniversity('chittagong-university', 'University of Chittagong'),
  _BdUniversity('rajshahi-university', 'University of Rajshahi'),
  _BdUniversity('jahangirnagar-university', 'Jahangirnagar University'),
  _BdUniversity('khulna-university', 'Khulna University'),
  _BdUniversity('bau', 'Bangladesh Agricultural University'),
  _BdUniversity('islamic-university-kushtia', 'Islamic University, Kushtia'),
  _BdUniversity('national-university', 'National University Bangladesh'),
  _BdUniversity(
    'sust',
    'Shahjalal University of Science and Technology (SUST)',
  ),
  _BdUniversity('pust', 'Pabna University of Science and Technology'),
  _BdUniversity('nstu', 'Noakhali Science and Technology University'),
  _BdUniversity('just', 'Jessore University of Science and Technology'),
  _BdUniversity('mist', 'Military Institute of Science and Technology (MIST)'),
  _BdUniversity(
    'bauet',
    'Bangladesh Army University of Engineering and Technology',
  ),
  _BdUniversity(
    'bsmrstu',
    'Bangabandhu Sheikh Mujibur Rahman Science and Technology University',
  ),
  _BdUniversity(
    'hstu',
    'Hajee Mohammad Danesh Science and Technology University',
  ),
  _BdUniversity(
    'ruet',
    'Rajshahi University of Engineering and Technology (RUET)',
  ),
  _BdUniversity(
    'cuet',
    'Chittagong University of Engineering and Technology (CUET)',
  ),
  _BdUniversity(
    'kuet',
    'Khulna University of Engineering and Technology (KUET)',
  ),
  _BdUniversity(
    'duet',
    'Dhaka University of Engineering and Technology (DUET)',
  ),
  _BdUniversity('bup', 'Bangladesh University of Professionals (BUP)'),
  _BdUniversity(
    'bsmrau',
    'Bangabandhu Sheikh Mujibur Rahman Agricultural University',
  ),
  // Private
  _BdUniversity('brac-university', 'BRAC University', isPublic: false),
  _BdUniversity(
    'north-south-university',
    'North South University (NSU)',
    isPublic: false,
  ),
  _BdUniversity(
    'east-west-university',
    'East West University (EWU)',
    isPublic: false,
  ),
  _BdUniversity(
    'iub',
    'Independent University Bangladesh (IUB)',
    isPublic: false,
  ),
  _BdUniversity(
    'aiub',
    'American International University-Bangladesh (AIUB)',
    isPublic: false,
  ),
  _BdUniversity(
    'uiu',
    'United International University (UIU)',
    isPublic: false,
  ),
  _BdUniversity(
    'diu',
    'Daffodil International University (DIU)',
    isPublic: false,
  ),
  _BdUniversity('seu', 'Southeast University', isPublic: false),
  _BdUniversity('uap', 'University of Asia Pacific (UAP)', isPublic: false),
  _BdUniversity(
    'aust',
    'Ahsanullah University of Science and Technology (AUST)',
    isPublic: false,
  ),
  _BdUniversity(
    'stamford-university',
    'Stamford University Bangladesh',
    isPublic: false,
  ),
  _BdUniversity(
    'green-university',
    'Green University of Bangladesh',
    isPublic: false,
  ),
  _BdUniversity(
    'primeasia-university',
    'Prime Asia University',
    isPublic: false,
  ),
  _BdUniversity(
    'leading-university',
    'Leading University, Sylhet',
    isPublic: false,
  ),
  _BdUniversity('cou', 'City University', isPublic: false),
  _BdUniversity(
    'premier-university',
    'Premier University, Chittagong',
    isPublic: false,
  ),
  _BdUniversity(
    'bgc-trust',
    'BGC Trust University Bangladesh',
    isPublic: false,
  ),
];

// ---------------------------------------------------------------------------

class CompleteProfilePage extends StatefulWidget {
  final User user;
  const CompleteProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customUniController = TextEditingController();
  final _uniSearchController = TextEditingController();

  _BdUniversity? _selectedUni;
  bool _useCustomUni = false;
  Department? _selectedDept;
  String? _selectedGender;
  List<_BdUniversity> _filteredUnis = _bdUniversities;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _uniSearchController.addListener(_filterUniversities);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customUniController.dispose();
    _uniSearchController.dispose();
    super.dispose();
  }

  void _filterUniversities() {
    final q = _uniSearchController.text.toLowerCase();
    setState(() {
      _filteredUnis = q.isEmpty
          ? _bdUniversities
          : _bdUniversities
                .where((u) => u.name.toLowerCase().contains(q))
                .toList();
    });
  }

  String _slugify(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9-]'), '');

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Determine university
    String uniId;
    String uniName;
    if (_useCustomUni) {
      final typedName = _customUniController.text.trim();
      uniId = _slugify(typedName);
      uniName = typedName;
    } else {
      uniId = _selectedUni!.id;
      uniName = _selectedUni!.name;
    }

    // Ensure university record exists in Firestore (via AdminBloc)
    context.read<AdminBloc>().add(
      AddUniversity(
        University(
          id: uniId,
          name: uniName,
          description: '',
          logoUrl: '',
          location: 'Bangladesh',
          isPublic: _useCustomUni ? true : _selectedUni!.isPublic,
          researchScore: 0.0,
          qsRankingScore: 0.0,
        ),
      ),
    );

    // Update user profile
    final updatedUser = User(
      id: widget.user.id,
      name: _nameController.text.trim(),
      email: widget.user.email,
      universityId: uniId,
      gender: _selectedGender,
      isVerified: widget.user.isVerified,
      userType: widget.user.userType,
      profilePictureUrl: widget.user.profilePictureUrl,
      department: _selectedDept,
      postCount: widget.user.postCount,
      commentCount: widget.user.commentCount,
      resolvedIssuesCount: widget.user.resolvedIssuesCount,
      receivedVotesCount: widget.user.receivedVotesCount,
      givenVotesCount: widget.user.givenVotesCount,
      reputationScore: widget.user.reputationScore,
      currentBadge: widget.user.currentBadge,
      achievements: widget.user.achievements,
      streakDays: widget.user.streakDays,
      activityLog: widget.user.activityLog,
    );

    context.read<AuthBloc>().add(AuthUpdateRequested(updatedUser));
  }

  // -------------------------------------------------------------------------
  // UI helpers
  // -------------------------------------------------------------------------

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(80),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      labelStyle: GoogleFonts.poppins(fontSize: 13),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.primary,
        letterSpacing: 0.4,
      ),
    ),
  );

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage()),
            (_) => false,
          );
        } else if (state is AuthUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundImage:
                                widget.user.profilePictureUrl.isNotEmpty
                                ? NetworkImage(widget.user.profilePictureUrl)
                                : null,
                            backgroundColor: Colors.white,
                            child: widget.user.profilePictureUrl.isEmpty
                                ? const Icon(
                                    Iconsax.user,
                                    size: 36,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.user.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.user.email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                title: Text(
                  'Complete Your Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
              ),
            ),

            // ── Form ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome note
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Just a few details to personalise your campus experience.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Name ─────────────────────────────────────────
                      _sectionHeader('Your Name'),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Full name', Iconsax.user),
                        style: GoogleFonts.poppins(fontSize: 14),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),

                      // ── Gender ───────────────────────────────────────
                      _sectionHeader('Gender'),
                      Row(
                        children: _genders.map((g) {
                          final selected = _selectedGender == g;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(
                                g,
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : null,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedGender = g),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedGender == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Please select your gender',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: colorScheme.error,
                            ),
                          ),
                        ),

                      // ── University ───────────────────────────────────
                      _sectionHeader('University'),

                      // Toggle: predefined vs custom
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _useCustomUni = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !_useCustomUni
                                      ? AppColors.primary
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(10),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Select from list',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: !_useCustomUni
                                          ? Colors.white
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _useCustomUni = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _useCustomUni
                                      ? AppColors.primary
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(10),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '+ Add my university',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: _useCustomUni
                                          ? Colors.white
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_useCustomUni) ...[
                        // ── Custom university text field
                        TextFormField(
                          controller: _customUniController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            'University name',
                            Iconsax.building,
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                          validator: (v) {
                            if (_useCustomUni &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Please enter your university name';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        // ── Search field
                        TextField(
                          controller: _uniSearchController,
                          decoration:
                              _inputDecoration(
                                'Search university…',
                                Iconsax.search_normal,
                              ).copyWith(
                                suffixIcon: _uniSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          _uniSearchController.clear();
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                              ),
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),

                        // Selected badge
                        if (_selectedUni != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.tick_circle,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedUni!.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedUni = null),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Uni list (shown when no selection yet or searching)
                        if (_selectedUni == null) ...[
                          const SizedBox(height: 6),
                          FormField<_BdUniversity>(
                            validator: (_) =>
                                _selectedUni == null && !_useCustomUni
                                ? 'Please select your university'
                                : null,
                            builder: (field) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 260,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: field.hasError
                                          ? colorScheme.error
                                          : colorScheme.outline.withAlpha(80),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _filteredUnis.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Center(
                                              child: Text(
                                                'No university found.\nUse "Add my university" tab.',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: colorScheme.outline,
                                                ),
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            shrinkWrap: true,
                                            itemCount: _filteredUnis.length,
                                            separatorBuilder: (_, __) =>
                                                Divider(
                                                  height: 1,
                                                  color: colorScheme.outline
                                                      .withAlpha(40),
                                                ),
                                            itemBuilder: (_, i) {
                                              final uni = _filteredUnis[i];
                                              return ListTile(
                                                dense: true,
                                                leading: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: uni.isPublic
                                                        ? Colors.green
                                                              .withAlpha(30)
                                                        : AppColors.primary
                                                              .withAlpha(20),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    uni.isPublic
                                                        ? Iconsax.buildings
                                                        : Iconsax.building_3,
                                                    size: 16,
                                                    color: uni.isPublic
                                                        ? Colors.green
                                                        : AppColors.primary,
                                                  ),
                                                ),
                                                title: Text(
                                                  uni.name,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  uni.isPublic
                                                      ? 'Public'
                                                      : 'Private',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: uni.isPublic
                                                        ? Colors.green
                                                        : AppColors.primary,
                                                  ),
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    _selectedUni = uni;
                                                    _uniSearchController
                                                        .clear();
                                                  });
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                if (field.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      left: 4,
                                    ),
                                    child: Text(
                                      field.errorText!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // ── Department ───────────────────────────────────
                      _sectionHeader('Department'),
                      DropdownButtonFormField<Department>(
                        value: _selectedDept,
                        decoration: _inputDecoration(
                          'Select department',
                          Iconsax.book,
                        ),
                        isExpanded: true,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        items: Department.values.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(
                              _deptLabel(d),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedDept = v),
                        validator: (_) => _selectedDept == null
                            ? 'Please select your department'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Sticky submit button ────────────────────────────────────────
        bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () {
                        // Validate gender separately (ChoiceChip has no built-in validator)
                        if (_selectedGender == null) {
                          setState(
                            () {},
                          ); // trigger rebuild to show gender error
                          return;
                        }
                        _submit();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
                          const Icon(Iconsax.arrow_right_3, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Continue to Campus Saga',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Department display labels
// ---------------------------------------------------------------------------
String _deptLabel(Department d) {
  const map = {
    Department.cse: 'Computer Science and Engineering (CSE)',
    Department.swe: 'Software Engineering (SWE)',
    Department.eee: 'Electrical and Electronic Engineering (EEE)',
    Department.civil: 'Civil Engineering',
    Department.mechanical: 'Mechanical Engineering',
    Department.textile: 'Textile Engineering',
    Department.architecture: 'Architecture',
    Department.mechatronics: 'Mechatronics Engineering',
    Department.chemical: 'Chemical Engineering',
    Department.aeronautical: 'Aeronautical Engineering',
    Department.biomedical: 'Biomedical Engineering',
    Department.foodEngineering: 'Food Engineering',
    Department.physics: 'Physics',
    Department.chemistry: 'Chemistry',
    Department.mathematics: 'Mathematics',
    Department.statistics: 'Statistics',
    Department.biology: 'Biology',
    Department.microbiology: 'Microbiology',
    Department.biotechnology: 'Biotechnology',
    Department.environmentalScience: 'Environmental Science',
    Department.bba: 'Business Administration (BBA)',
    Department.accounting: 'Accounting',
    Department.finance: 'Finance',
    Department.management: 'Management',
    Department.marketing: 'Marketing',
    Department.hrm: 'Human Resource Management',
    Department.tourismAndHospitality: 'Tourism and Hospitality',
    Department.internationalBusiness: 'International Business',
    Department.english: 'English',
    Department.bangla: 'Bangla',
    Department.history: 'History',
    Department.philosophy: 'Philosophy',
    Department.islamicStudies: 'Islamic Studies',
    Department.journalism: 'Journalism and Mass Communication',
    Department.mediaStudies: 'Media Studies',
    Department.fineArts: 'Fine Arts',
    Department.law: 'Law',
    Department.sociology: 'Sociology',
    Department.politicalScience: 'Political Science',
    Department.publicAdministration: 'Public Administration',
    Department.economics: 'Economics',
    Department.anthropology: 'Anthropology',
    Department.psychology: 'Psychology',
    Department.pharmacy: 'Pharmacy',
    Department.mbbs: 'MBBS (Medicine)',
    Department.nursing: 'Nursing',
    Department.dentalSurgery: 'Dental Surgery (BDS)',
    Department.publicHealth: 'Public Health',
    Department.physiotherapy: 'Physiotherapy',
    Department.agriculture: 'Agriculture',
    Department.fisheries: 'Fisheries',
    Department.forestry: 'Forestry',
    Department.veterinaryScience: 'Veterinary Science',
    Department.foodAndNutrition: 'Food and Nutrition',
  };
  return map[d] ?? d.toString().split('.').last;
}
