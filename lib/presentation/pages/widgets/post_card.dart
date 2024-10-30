// lib/pages/widgets/post_card.dart

import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String postId;

  const PostCard({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "User Name", // Placeholder
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text("This is a sample post description."), // Placeholder text
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: const Text("Resolve")),
                TextButton(onPressed: () {}, child: const Text("Report")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
