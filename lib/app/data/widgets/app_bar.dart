import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function()? onPressedLeading;
  final Function()? onPressedAction;
  final IconData? leadingIcon;
  final IconData? actionIcon;
  final bool popUpMenu; // Change the type to boolean
  final Widget? popUpMenuWidget; // Change the type to Widget
  final String title;

  CustomAppBar({
    Key? key,
    this.onPressedLeading,
    this.onPressedAction,
    required this.title,
    this.leadingIcon,
    this.actionIcon,
    this.popUpMenu = false,
    this.popUpMenuWidget, // Remove the "?" here
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
        style: TextStyle(fontFamily: 'Boogaloo', fontSize: 30),
      ),
      actions: [
        IconButton(
          onPressed: onPressedAction,
          icon: Icon(
            actionIcon,
            color: Colors.white,
          ),
        ),
        if (popUpMenu)
          popUpMenuWidget ??
              Container(), // Use "if" to conditionally include the popUpMenuWidget
      ],
      centerTitle: true,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
