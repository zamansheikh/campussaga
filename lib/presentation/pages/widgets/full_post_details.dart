import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/entities/user.dart';

class FullPostDetails extends StatelessWidget {
  final Post post;
  final User user;

  const FullPostDetails({
    Key? key,
    required this.post,
    required this.user,
  }) : super(key: key);

  double _calculatePercentage(int trueVotes, int falseVotes) {
    final totalVotes = trueVotes + falseVotes;
    return totalVotes == 0 ? 0.0 : trueVotes / totalVotes;
  }

  String _getIssueStatus() {
    DateTime referenceTime = post.feedback?.timestamp ?? post.timestamp;
    final timeDifference = DateTime.now().difference(referenceTime);

    return timeDifference.inDays > 2
        ? (post.trueVotes > post.falseVotes ? "Solved" : "Unsolved")
        : "Pending";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.person,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Anonymous",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      timeago.format(post.timestamp),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    _getIssueStatus(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                post.postTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                post.description,
              ),
            ),
            const SizedBox(height: 20),
            if (post.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrls[index],
                          width: 300,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Container(
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _calculatePercentage(post.trueVotes, post.falseVotes),
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }
}
