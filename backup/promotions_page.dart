import 'package:flutter/material.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
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
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return PromotionCard(
            club: 'Sample Club ${index + 1}',
            title: 'Sample Promotion Title',
            imageUrl: 'https://picsum.photos/seed/${index + 100}/400/200',
            date: 'September ${index + 1}, 2023',
            timeLeft: index == 0 ? 15 : null,
          );
        },
      ),
    );
  }
}

class PromotionCard extends StatelessWidget {
  final String club;
  final String title;
  final String imageUrl;
  final String date;
  final int? timeLeft;

  const PromotionCard({
    Key? key,
    required this.club,
    required this.title,
    required this.imageUrl,
    required this.date,
    this.timeLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (timeLeft != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Only $timeLeft hours left',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement learn more action
                    },
                    child: const Text('Learn More'),
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