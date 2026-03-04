import 'package:campussaga/core/injection_container.dart';
import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/domain/entities/university.dart';
import 'package:campussaga/presentation/bloc/university/university_bloc.dart';
import 'package:campussaga/presentation/pages/home/switch_campus_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class SwitcherWidget extends StatefulWidget {
  const SwitcherWidget({super.key});

  @override
  State<SwitcherWidget> createState() => _SwitcherWidgetState();
}

class _SwitcherWidgetState extends State<SwitcherWidget> {
  University? selectedUniversity;

  @override
  void initState() {
    super.initState();
    final state = sl<UniversityBloc>().state;
    if (state is! UniversityLoaded) {
      sl<UniversityBloc>().add(const FetchUniversitiesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.repeat, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Switch Campus',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── University list from DB ─────────────────────────────────
          Flexible(
            child: BlocBuilder<UniversityBloc, UniversityState>(
              bloc: sl<UniversityBloc>(),
              builder: (context, state) {
                if (state is UniversityLoading || state is UniversityInitial) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is UniversityError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.warning_2,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => sl<UniversityBloc>().add(
                            const FetchUniversitiesEvent(),
                          ),
                          icon: const Icon(Iconsax.refresh, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UniversityLoaded) {
                  final universities = state.universities;
                  if (universities.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No universities found in database.',
                        style: GoogleFonts.poppins(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shrinkWrap: true,
                      itemCount: universities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final uni = universities[index];
                        final isSelected = selectedUniversity?.id == uni.id;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => selectedUniversity = uni),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? AppColors.primary.withAlpha(25)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withAlpha(
                                    20,
                                  ),
                                  backgroundImage: uni.logoUrl.isNotEmpty
                                      ? NetworkImage(uni.logoUrl)
                                      : null,
                                  child: uni.logoUrl.isEmpty
                                      ? Text(
                                          uni.name.isNotEmpty
                                              ? uni.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        uni.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '@${uni.id.toLowerCase()}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // ── Actions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedUniversity == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SwitchCampusPage(
                                  universityId: selectedUniversity!.id
                                      .toUpperCase(),
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withAlpha(60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Visit Campus',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the campus switcher dialog
void showSwitcherWidget(BuildContext context) {
  showDialog(context: context, builder: (_) => const SwitcherWidget());
}
