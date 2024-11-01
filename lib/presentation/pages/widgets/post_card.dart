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
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              post.postTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8.0),

            // Description
            Text(
              post.description,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8.0),

            // Post Images
            if (post.imageUrls.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          post.imageUrls[index],
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12.0),

            // Voting Counts
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.green, size: 20),
                    const SizedBox(width: 4.0),
                    Text("True: ${post.trueVotes}"),
                  ],
                ),
                const SizedBox(width: 16.0),
                Row(
                  children: [
                    const Icon(Icons.thumb_down, color: Colors.red, size: 20),
                    const SizedBox(width: 4.0),
                    Text("False: ${post.falseVotes}"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Authority Feedback
            if (post.feedback != null) ...[
              const Divider(),
              Text(
                "Authority Feedback",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text(
                post.feedback!.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[800]),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_outlined,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 4.0),
                      Text("Agree: ${post.feedback!.agreeCount}"),
                    ],
                  ),
                  const SizedBox(width: 16.0),
                  Row(
                    children: [
                      const Icon(Icons.thumb_down_alt_outlined,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 4.0),
                      Text("Disagree: ${post.feedback!.disagreeCount}"),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12.0),

            // Student Comments Preview
            if (post.comments.isNotEmpty) ...[
              const Divider(),
              Text(
                "Student Comments",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: post.comments.take(3).map((comment) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "- ${comment.text}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  );
                }).toList(),
              ),
            ],

            // University Authority Actions
            if (user.userType == UserType.university && user.isVerified) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement resolve functionality
                    },
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    label: const Text("Resolve"),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement reject functionality
                    },
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text("Reject"),
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
