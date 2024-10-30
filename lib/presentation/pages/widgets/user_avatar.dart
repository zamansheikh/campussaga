// lib/pages/widgets/user_avatar.dart

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const UserAvatar({Key? key, required this.imageUrl, this.radius = 20.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl),
      backgroundColor: Colors.grey[200],
      onBackgroundImageError: (_, __) => const Icon(Icons.person),
    );
  }
}
