import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  // Example list of promotions - normally this data would come from a backend or database
  List<Promotion> promotions = [
    Promotion(
      id: '1',
      userId: 'user1',
      universityId: 'uni1',
      promotionTitle: 'Scholarship Program',
      description: 'Get a scholarship for excellent academic performance.',
      timestamp: DateTime.now(),
      imageUrls: [
        'https://via.placeholder.com/150',
        'https://via.placeholder.com/150'
      ],
      trueVotes: 25,
      falseVotes: 5,
    ),
    Promotion(
      id: '2',
      userId: 'user2',
      universityId: 'uni2',
      promotionTitle: 'New Research Opportunity',
      description: 'Join our upcoming research project in AI technology.',
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      imageUrls: ['https://via.placeholder.com/150'],
      trueVotes: 40,
      falseVotes: 10,
    ),
  ];

  void toggleTrueVote(Promotion promotion) {
    setState(() {
      int index = promotions.indexOf(promotion);
      promotions[index] = promotion.toggleTrueVote('user1'); // Example userId
    });
  }

  void toggleFalseVote(Promotion promotion) {
    setState(() {
      int index = promotions.indexOf(promotion);
      promotions[index] = promotion.toggleFalseVote('user1'); // Example userId
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        title: const Text(
          "Promotions",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return PromotionCard(
            promotion: promotion,
            onTrueVote: () => toggleTrueVote(promotion),
            onFalseVote: () => toggleFalseVote(promotion),
          );
        },
      ),
    );
  }
}

class PromotionCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onTrueVote;
  final VoidCallback onFalseVote;

  const PromotionCard({
    required this.promotion,
    required this.onTrueVote,
    required this.onFalseVote,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              promotion.promotionTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              promotion.description,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'Posted on ${DateFormat.yMMMd().format(promotion.timestamp)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            promotion.imageUrls.isNotEmpty
                ? SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: promotion.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.network(
                            promotion.imageUrls[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: promotion.hasUserVotedTrue('user1')
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      onPressed: onTrueVote,
                    ),
                    Text('${promotion.trueVotes}'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.thumb_down,
                        color: promotion.hasUserVotedFalse('user1')
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: onFalseVote,
                    ),
                    Text('${promotion.falseVotes}'),
                  ],
                ),
                const Text(
                  'Vote on Promotion',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class PromotionCardNew extends StatelessWidget {
  final String club;
  final String title;
  final String imageUrl;
  final String date;
  final int? timeLeft;

  const PromotionCardNew({
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
