// lib/pages/home/home_page.dart

import 'package:campus_saga/presentation/pages/widgets/post_card.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: ListView.builder(
        itemCount: 10, // Placeholder count for posts
        itemBuilder: (context, index) {
          return PostCard(postId: 'post_$index'); // Dummy postId
        },
      ),
    );
  }
}
