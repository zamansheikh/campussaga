import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/entities/user.dart';

import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final User user;

  const PostCard({Key? key, required this.post, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              post.postTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8.0),
            Text(
              post.description,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8.0),

            // Displaying post images
            if (post.imageUrls.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Image.network(
                        post.imageUrls[index],
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8.0),
            // Display voting counts
            Row(
              children: [
                Text("True votes: ${post.trueVotes}"),
                const SizedBox(width: 16.0),
                Text("False votes: ${post.falseVotes}"),
              ],
            ),
            const SizedBox(height: 8.0),

            // Display feedback if available
            if (post.feedback != null) ...[
              Text(
                "Authority Feedback:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(post.feedback!.message,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Text("Agree: ${post.feedback!.agreeCount}"),
                  const SizedBox(width: 16.0),
                  Text("Disagree: ${post.feedback!.disagreeCount}"),
                ],
              ),
            ],

            const SizedBox(height: 8.0),

            // Display comments preview
            if (post.comments.length > 1) ...[
              Text(
                "Student Comments:", // Displaying student comments if available
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: post.comments
                    .take(3) // Limiting to first 3 comments for preview
                    .map(
                      (comment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "- ${comment.text}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            //this section only visible to university authority
            if (user.userType == UserType.university && user.isVerified) ...[
              const SizedBox(height: 8.0),
              // Action buttons for resolve and report
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // Resolve action - TODO: handle resolve functionality
                    },
                    child: const Text("Resolve"),
                  ),
                  TextButton(
                    onPressed: () {
                      // Report action - TODO: handle report functionality
                    },
                    child: const Text("Reject"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
