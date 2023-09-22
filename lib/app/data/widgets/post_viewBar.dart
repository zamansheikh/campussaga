import 'package:flutter/material.dart';

class PostViewBar extends StatelessWidget implements PreferredSizeWidget {
  final Function()? onPressedLeading;
  final Function()? onPressedAction;
  final IconData? leadingIcon;
  final IconData? actionIcon;

  final String title;

  PostViewBar({
    Key? key,
    this.onPressedLeading,
    this.onPressedAction,
    required this.title,
    this.leadingIcon,
    this.actionIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFF207BFF),
      leading: IconButton(
        onPressed: onPressedLeading,
        icon: Icon(
          leadingIcon,
          color: Colors.white,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontFamily: 'Boogaloo', fontSize: 20),
      ),
      actions: [
        IconButton(
          onPressed: onPressedAction,
          icon: Icon(
            actionIcon,
            color: Colors.white,
          ),
        ),
      ],
      centerTitle: true,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
