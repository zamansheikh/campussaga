import 'package:campus_saga/components/tool_bar.dart';
import 'package:campus_saga/components/user_avatar.dart';
import 'package:campus_saga/config/app_routes.dart';
import 'package:campus_saga/config/app_strings.dart';
import 'package:campus_saga/styles/app_text.dart';
import 'package:flutter/material.dart';

enum profileMenu { edit, logout }

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ToolBar(
        appBarName: AppStrings.profile,
        actions: [
          PopupMenuButton<profileMenu>(
            onSelected: (value) {
              switch (value) {
                case profileMenu.edit:
                  Navigator.of(context).pushNamed(AppRoutes.edit_profile);
                  break;
                case profileMenu.logout:
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  break;
                default:
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text(AppStrings.editProfile),
                  value: profileMenu.edit,
                ),
                PopupMenuItem(
                  child: Text(AppStrings.logout),
                  value: profileMenu.logout,
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          UserAvater(
            size: 90,
          ),
          Text(
            AppStrings.name,
            style: AppText.header2,
          ),
          SizedBox(
            height: 16,
          ),
          Text(
            AppStrings.country,
            style: AppText.subtitle3,
          ),
          SizedBox(
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text("722"),
                  Text(AppStrings.followers),
                ],
              ),
              Column(
                children: [
                  Text("130"),
                  Text(AppStrings.posts),
                ],
              ),
              Column(
                children: [
                  Text("1"),
                  Text(AppStrings.following),
                ],
              ),
            ],
          ),
          Divider(
            thickness: 2,
            indent: 30,
            endIndent: 30,
            height: 24,
          ),
        ],
      ),
    );
  }
}
