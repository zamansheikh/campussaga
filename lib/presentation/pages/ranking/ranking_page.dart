import 'package:campussaga/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campussaga/core/constants/app_constants.dart';
import 'package:campussaga/core/injection_container.dart';
import 'package:campussaga/domain/entities/university.dart';
import 'package:campussaga/presentation/bloc/university/university_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<University> universities = [];
  String searchQuery = '';
  String filter = 'All';
  bool _descExpanded = false;

  List<University> get filteredUniversities {
    List<University> filtered = universities.where((university) {
      return university.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (filter == 'Public') {
      filtered = filtered.where((university) => university.isPublic).toList();
    } else if (filter == 'Private') {
      filtered = filtered.where((university) => !university.isPublic).toList();
    }

    return filtered;
  }

  @override
  void initState() {
    sl<UniversityBloc>().add(FetchUniversitiesEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
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
                Iconsax.ranking_1,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Rankings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      body: BlocConsumer<UniversityBloc, UniversityState>(
        listener: (context, state) {
          if (state is UniversityError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is UniversityLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (state is UniversityLoaded) {
            universities = state.universities;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                sl<UniversityBloc>().add(FetchUniversitiesEvent());
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'University Rankings 2025',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Collapsible description
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState: _descExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: Text(
                              AppConstants.UNIVERSITY_RANKING_DESCRIPTION,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              AppConstants.UNIVERSITY_RANKING_DESCRIPTION,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _descExpanded = !_descExpanded),
                            child: Text(
                              _descExpanded ? 'Show less' : 'Show more',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Search bar
                          TextField(
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search universities…',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                              prefixIcon: const Icon(
                                Iconsax.search_normal,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Pill filter row
                          Row(
                            children: [
                              _FilterPill(
                                label: 'All',
                                selected: filter == 'All',
                                onTap: () => setState(() => filter = 'All'),
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                label: 'Public',
                                selected: filter == 'Public',
                                onTap: () => setState(() => filter = 'Public'),
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                label: 'Private',
                                selected: filter == 'Private',
                                onTap: () => setState(() => filter = 'Private'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final university = filteredUniversities[index];
                      return UniversityCard(
                        university: university,
                        rank: index + 1,
                      );
                    }, childCount: filteredUniversities.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          } else if (state is UniversityError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.warning_2,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(state.message, style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class UniversityCard extends StatefulWidget {
  final University university;
  final int rank;
  const UniversityCard({Key? key, required this.university, required this.rank})
    : super(key: key);

  @override
  State<UniversityCard> createState() => _UniversityCardState();
}

class _UniversityCardState extends State<UniversityCard> {
  bool showMetrics = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = Theme.of(context).colorScheme.outline.withAlpha(50);

    Color rankBg;
    Color rankFg;
    if (widget.rank == 1) {
      rankBg = const Color(0xFFFFD700);
      rankFg = const Color(0xFF7A5C00);
    } else if (widget.rank == 2) {
      rankBg = const Color(0xFFB0BEC5);
      rankFg = const Color(0xFF263238);
    } else if (widget.rank == 3) {
      rankBg = const Color(0xFFFF8A65);
      rankFg = const Color(0xFF4E2100);
    } else {
      rankBg = const Color(0xFFEEF0FF);
      rankFg = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rankBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${widget.rank}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: rankFg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.university.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.location,
                            size: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              widget.university.location,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.university.rankingScore.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ToggleChip(
                  label: 'Metrics',
                  icon: Iconsax.chart,
                  selected: showMetrics,
                  onTap: () => setState(() => showMetrics = true),
                ),
                const SizedBox(width: 8),
                _ToggleChip(
                  label: 'Details',
                  icon: Iconsax.info_circle,
                  selected: !showMetrics,
                  onTap: () => setState(() => showMetrics = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (showMetrics) ...[
              _buildMetricRow(
                label: 'QS Score',
                score: widget.university.qsRankingScore,
                color: AppColors.primary,
                icon: Iconsax.bookmark,
              ),
              _buildMetricRow(
                label: 'Academic',
                score: widget.university.academicScore,
                color: const Color(0xFF4CAF50),
                icon: Iconsax.teacher,
              ),
              _buildMetricRow(
                label: 'Research',
                score: widget.university.researchScore,
                color: Color(0xFFFF9800),
                icon: Iconsax.microscope,
              ),
              _buildMetricRow(
                label: 'Satisfaction',
                score: widget.university.satisfactionPercentage,
                color: const Color(0xFF00BCD4),
                icon: Iconsax.emoji_happy,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem(
                    Iconsax.people,
                    '${widget.university.studentCount}',
                    'Students',
                  ),
                  _buildDetailItem(
                    Iconsax.teacher,
                    '${widget.university.facultyCount}',
                    'Faculty',
                  ),
                  _buildDetailItem(
                    Iconsax.book_1,
                    '${widget.university.programsOffered}',
                    'Programs',
                  ),
                  _buildDetailItem(
                    Iconsax.calendar,
                    '${widget.university.establishmentYear}',
                    'Est.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.university.description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required double score,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                color: color,
                backgroundColor: color.withAlpha(30),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '${score.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

// ── Toggle chip helper ────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outline.withAlpha(80),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter pill helper ────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outline.withAlpha(80),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
