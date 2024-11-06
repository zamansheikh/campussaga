import 'package:campus_saga/domain/entities/university.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<University> universities = [
    University(
      id: '1',
      name: 'Daffodil International University',
      location: 'Dhaka, Bangladesh',
      isPublic: false,
      researchScore: 75.0,
      qsRankingScore: 70.0,
      totalPosts: 100,
      totalSolvedPosts: 80,
      interactions: 200,
      studentCount: 25000,
      facultyCount: 800,
      programsOffered: 50,
      establishmentYear: 2002,
      academicScore: 85.0,
      satisfactionScore: 90.0,
    ),
    University(
      id: '2',
      name: 'North South University',
      location: 'Dhaka, Bangladesh',
      isPublic: false,
      researchScore: 80.0,
      qsRankingScore: 75.0,
      totalPosts: 120,
      totalSolvedPosts: 90,
      interactions: 250,
      studentCount: 20000,
      facultyCount: 600,
      programsOffered: 40,
      establishmentYear: 1993,
      academicScore: 80.0,
      satisfactionScore: 85.0,
    ),
    University(
      id: '3',
      name: 'University of Dhaka',
      location: 'Dhaka, Bangladesh',
      isPublic: true,
      researchScore: 85.0,
      qsRankingScore: 80.0,
      totalPosts: 150,
      totalSolvedPosts: 120,
      interactions: 300,
      studentCount: 30000,
      facultyCount: 1000,
      programsOffered: 60,
      establishmentYear: 1921,
      academicScore: 90.0,
      satisfactionScore: 95.0,
    ),
  ];

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
      body: Padding(
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
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
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
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
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
              _buildMetricRow(
                  'Satisfaction', university.satisfactionScore, Colors.blue),
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
