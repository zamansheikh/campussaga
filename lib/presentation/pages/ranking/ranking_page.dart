import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/domain/entities/university.dart';
import 'package:campus_saga/presentation/bloc/university/university_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<University> universities = [];

  String searchQuery = '';
  String filter = 'All Universities';
  bool showMetrics = true;

  List<University> get filteredUniversities {
    List<University> filtered = universities.where((university) {
      return university.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (filter == 'Public Universities') {
      filtered = filtered.where((university) => university.isPublic).toList();
    } else if (filter == 'Private Universities') {
      filtered = filtered.where((university) => !university.isPublic).toList();
    }

    return filtered;
  }

  @override
  void initState() {
    // universities.sort((a, b) => a.qsRankingScore.compareTo(b.qsRankingScore));
    sl<UniversityBloc>().add(FetchUniversitiesEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'University Rankings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ),
      body: BlocConsumer<UniversityBloc, UniversityState>(
        listener: (context, state) {
          if (state is UniversityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UniversityLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is UniversityLoaded && state.universities.isEmpty) {
            return Center(
              child: Text('No universities found!'),
            );
          } else if (state is UniversityLoaded) {
            universities = state.universities;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'University Rankings 2023',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore top universities based on academic excellence, research output, and student satisfaction.',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search universities',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: filter,
                        items: [
                          DropdownMenuItem(
                            value: 'All Universities',
                            child: Text('All Universities'),
                          ),
                          DropdownMenuItem(
                            value: 'Public Universities',
                            child: Text('Public Universities'),
                          ),
                          DropdownMenuItem(
                            value: 'Private Universities',
                            child: Text('Private Universities'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            filter = value!;
                          });
                        },
                        underline: Container(),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredUniversities.length,
                      itemBuilder: (context, index) {
                        final university = filteredUniversities[index];
                        return UniversityCard(
                          university: university,
                          rank: index + 1,
                          showMetrics: showMetrics,
                          onToggleView: () {
                            setState(() {
                              showMetrics = !showMetrics;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else if (state is UniversityError) {
            return Center(
              child: Text(state.message),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}

class UniversityCard extends StatelessWidget {
  final University university;
  final int rank;
  final bool showMetrics;
  final VoidCallback onToggleView;

  const UniversityCard({
    Key? key,
    required this.university,
    required this.rank,
    required this.showMetrics,
    required this.onToggleView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              university.name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Rank: #$rank',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ToggleButtons(
              children: [Text('Metrics'), Text('Details')],
              onPressed: (index) => onToggleView(),
              isSelected: [showMetrics, !showMetrics],
              selectedColor: Colors.black,
              color: Colors.grey,
              fillColor: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            if (showMetrics) ...[
              _buildMetricRow(
                  'Academic', university.academicScore, Colors.green),
              _buildMetricRow(
                  'Research', university.researchScore, Colors.orange),
              _buildMetricRow('Satisfaction', university.satisfactionPercentage,
                  Colors.blue),
            ] else ...[
              Row(
                children: [
                  _buildDetailItem(
                      Icons.group, '${university.studentCount} Students'),
                  _buildDetailItem(
                      Icons.person, '${university.facultyCount} Faculty'),
                  _buildDetailItem(
                      Icons.book, '${university.programsOffered} Programs'),
                  _buildDetailItem(Icons.calendar_today,
                      'Est. ${university.establishmentYear}'),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, double score, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 100,
            color: color,
            backgroundColor: color.withOpacity(0.2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${score.toStringAsFixed(0)}%',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
