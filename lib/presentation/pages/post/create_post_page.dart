// lib/pages/post/create_post_page.dart

import 'package:flutter/material.dart';

class CreatePostPage extends StatelessWidget {
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Post Description",
                hintText: "Describe the issue or share information",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Action to submit post goes here
              },
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}
