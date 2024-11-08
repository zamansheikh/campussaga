import 'package:campus_saga/domain/entities/post.dart';
import 'package:flutter/material.dart';

class PredictionWidget extends StatelessWidget {
  final Post post;

  const PredictionWidget({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final postAge = DateTime.now().difference(post.timestamp);
    final isTwoDaysOld = postAge.inDays >= 2;
    final totalVotes = post.trueVotes + post.falseVotes;
    final trueVoteRatio = totalVotes > 0 ? post.trueVotes / totalVotes : 0;
    final falseVoteRatio = totalVotes > 0 ? post.falseVotes / totalVotes : 0;

    String predictionText;
    Color predictionColor;

    if (!isTwoDaysOld) {
      predictionText = "AI is calculating...";
      predictionColor = Colors.grey[600]!;
    } else if (trueVoteRatio >= 0.75) {
      predictionText = "True Issue";
      predictionColor = Colors.green[600]!;
    } else if (falseVoteRatio > 0.5) {
      predictionText = "False Claim";
      predictionColor = Colors.red[600]!;
    } else {
      predictionText = "Inconclusive";
      predictionColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        predictionText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: predictionColor,
        ),
      ),
    );
  }
}
