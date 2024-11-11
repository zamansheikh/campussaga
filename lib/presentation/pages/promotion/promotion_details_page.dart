import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PromotionDetailPage extends StatelessWidget {
  final Promotion promotion;

  const PromotionDetailPage({Key? key, required this.promotion})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeLeft = promotion.expiryDate != null
        ? promotion.expiryDate!.difference(DateTime.now()).inHours.toString()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(promotion.promotionTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promotion image
            Image.network(
              promotion.imageUrls.isNotEmpty
                  ? promotion.imageUrls.first
                  : 'https://placehold.co/600x400',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            // Club name
            Text(
              promotion.clubName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Promotion title
            Text(
              promotion.promotionTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            // Date posted
            Text(
              'Posted on: ${DateFormat.yMMMd().format(promotion.timestamp)}',
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
            // Promotion description
            Text(
              promotion.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Event link button
            if (promotion.eventLink != null) ...[
              ElevatedButton(
                onPressed: () {
                  launchURL(promotion.eventLink!);
                },
                child: const Text('Go to Event'),
              ),
            ],
            const SizedBox(height: 16),
            // Likes and dislikes section
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    color: promotion.hasUserVotedTrue == true ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () {
                    // Handle upvote
                  },
                ),
                Text('${promotion.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    color: promotion.hasUserVotedFalse == true ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    // Handle downvote
                  },
                ),
                Text('${promotion.dislikes}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
