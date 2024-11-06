import 'package:flutter/material.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  // Example list of university data - this will usually come from a data source
  List<Map<String, dynamic>> universities = [
    {
      'name': 'University A',
      'location': 'City X',
      'researchScore': 85.0,
      'qsRankingScore': 90.0,
      'totalPosts': 120,
      'totalSolvedPosts': 80,
      'interactions': 300,
      'isPublic': true,
    },
    {
      'name': 'University B',
      'location': 'City Y',
      'researchScore': 75.0,
      'qsRankingScore': 85.0,
      'totalPosts': 100,
      'totalSolvedPosts': 60,
      'interactions': 250,
      'isPublic': false,
    },
    // Add more universities as needed
  ];

  List<Map<String, dynamic>> filteredUniversities = [];
  String searchQuery = '';
  bool showPublicOnly = true;

  @override
  void initState() {
    super.initState();
    filteredUniversities =
        universities; // Initial display shows all universities
  }

  void updateSearchResults() {
    setState(() {
      filteredUniversities = universities.where((university) {
        final matchesSearch = university['name']
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
        final matchesFilter =
            showPublicOnly ? university['isPublic'] : !university['isPublic'];
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  double calculateRankingScore(Map<String, dynamic> university) {
    double publicScore = 0.8 *
        ((0.5 * university['researchScore']) +
            (0.5 * university['qsRankingScore']));
    double appActivityScore = 0.2 *
        (university['totalPosts'] * 0.5 +
            university['totalSolvedPosts'] * 0.3 +
            university['interactions'] * 0.2);
    return publicScore + appActivityScore;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        title: Text(
          "Rankings",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search University',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
                updateSearchResults();
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                // Wrap the DropdownButton with a Container for decoration
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<bool>(
                          value: showPublicOnly,
                          borderRadius: BorderRadius.circular(8),
                          items: [
                            DropdownMenuItem(
                              value: true,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("Public"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("Private"),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              showPublicOnly = value!;
                              updateSearchResults();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredUniversities.length,
                itemBuilder: (context, index) {
                  final university = filteredUniversities[index];
                  final rankingScore = calculateRankingScore(university);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            university['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Location: ${university['location']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Research Score: ${university['researchScore']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'QS Ranking Score: ${university['qsRankingScore']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'App Activity Score: ${university['totalPosts']} posts, '
                            '${university['totalSolvedPosts']} solved posts, '
                            '${university['interactions']} interactions',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Ranking Score: ${rankingScore.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
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
