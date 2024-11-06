import 'package:campus_saga/core/utils/utils.dart';
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
      clubName: 'Science Club',
      timestamp: DateTime.now(),
      expiryDate: DateTime.now().add(Duration(days: 2)),
      imageUrls: [
        'https://picsum.photos/seed/150/400/200',
        'https://picsum.photos/seed/151/400/200',
      ],
      likes: 25,
      dislikes: 5,
      eventLink: 'https://zamansheikh.com',
    ),
    Promotion(
      id: '2',
      userId: 'user2',
      universityId: 'uni2',
      promotionTitle: 'New Research Opportunity',
      description: 'Join our upcoming research project in AI technology.',
      clubName: 'AI Club',
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      expiryDate: DateTime.now().add(Duration(days: 5)),
      imageUrls: ['https://picsum.photos/seed/100/400/200'],
      likes: 40,
      dislikes: 10,
      eventLink: 'https://zamansheikh.com',
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
          final timeLeft = promotion.expiryDate != null
              ? promotion.expiryDate!
                  .difference(DateTime.now())
                  .inHours
                  .toString()
              : null;

          return PromotionCardNew(
            club: promotion.clubName,
            title: promotion.promotionTitle,
            imageUrl: promotion.imageUrls.isNotEmpty
                ? promotion.imageUrls.first
                : 'https://placehold.co/600x400',
            date: DateFormat.yMMMd().format(promotion.timestamp),
            timeLeft: timeLeft,
            onTrueVote: () => toggleTrueVote(promotion),
            onFalseVote: () => toggleFalseVote(promotion),
            likes: promotion.likes,
            dislikes: promotion.dislikes,
            hasUserVotedTrue: promotion.hasUserVotedTrue('user1'),
            hasUserVotedFalse: promotion.hasUserVotedFalse('user1'),
            eventLink: promotion.eventLink,
          );
        },
      ),
    );
  }
}

class PromotionCardNew extends StatelessWidget {
  final String club;
  final String title;
  final String imageUrl;
  final String date;
  final String? timeLeft;
  final VoidCallback onTrueVote;
  final VoidCallback onFalseVote;
  final int likes;
  final int dislikes;
  final bool hasUserVotedTrue;
  final bool hasUserVotedFalse;
  final String? eventLink;

  const PromotionCardNew({
    Key? key,
    required this.club,
    required this.title,
    required this.imageUrl,
    required this.date,
    this.timeLeft,
    required this.onTrueVote,
    required this.onFalseVote,
    required this.likes,
    required this.dislikes,
    required this.hasUserVotedTrue,
    required this.hasUserVotedFalse,
    this.eventLink,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: hasUserVotedTrue ? Colors.blue : Colors.grey,
                          ),
                          onPressed: onTrueVote,
                        ),
                        Text('$likes'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.thumb_down,
                            color: hasUserVotedFalse ? Colors.red : Colors.grey,
                          ),
                          onPressed: onFalseVote,
                        ),
                        Text('$dislikes'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Open the event link
                        eventLink != null
                            ? launchURL(eventLink!)
                            : print('No event link provided');
                      },
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
