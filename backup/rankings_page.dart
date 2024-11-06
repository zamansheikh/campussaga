import 'package:flutter/material.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  RankingsPageState createState() => RankingsPageState();
}

class RankingsPageState extends State<RankingsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Rankings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo, Colors.purple],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search universities',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return UniversityRankCard(
                  name: 'University ${index + 1}',
                  rank: index + 1,
                  metrics: [
                    Metric('Academic', 80 + index, Colors.green),
                    Metric('Research', 70 + index, Colors.yellow),
                    Metric('Satisfaction', 90 - index, Colors.blue),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Metric {
  final String name;
  final int value;
  final Color color;

  Metric(this.name, this.value, this.color);
}

class UniversityRankCard extends StatelessWidget {
  final String name;
  final int rank;
  final List<Metric> metrics;

  const UniversityRankCard({
    Key? key,
    required this.name,
    required this.rank,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(name[0]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Rank: #$rank',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...metrics.map((metric) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(metric.name),
                        Text('${metric.value}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: metric.value / 100,
                      color: metric.color,
                      backgroundColor: metric.color.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
