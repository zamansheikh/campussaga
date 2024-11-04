import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Post post;
  final User user;
  final VoidCallback? onResolve;
  final VoidCallback? onReject;

  const PostCard({
    Key? key, 
    required this.post, 
    required this.user,
    this.onResolve,
    this.onReject,
  }) : super(key: key);

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
            // Header with timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    post.postTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Text(
                  timeago.format(post.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
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
                      child: GestureDetector(
                        onTap: () => _showFullImage(context, post.imageUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: post.imageUrls[index],
                            width: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12.0),

            // Voting Counts with interaction
            Row(
              children: [
                _VoteButton(
                  icon: Icons.thumb_up,
                  color: Colors.green,
                  count: post.trueVotes,
                  label: "True",
                  onPressed: () {}, // TODO: Implement voting
                ),
                const SizedBox(width: 16.0),
                _VoteButton(
                  icon: Icons.thumb_down,
                  color: Colors.red,
                  count: post.falseVotes,
                  label: "False",
                  onPressed: () {}, // TODO: Implement voting
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Rest of the widget remains the same...
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback? onPressed;

  const _VoteButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4.0),
            Text("$label: $count"),
          ],
        ),
      ),
    );
  }
}