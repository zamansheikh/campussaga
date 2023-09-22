import 'package:campus_saga/components/post_item.dart';
import 'package:campus_saga/config/app_icons.dart';
import 'package:campus_saga/config/app_strings.dart';
import 'package:campus_saga/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  List<String> users = [];
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    mockUserFromServer();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 1,
        centerTitle: false,
        title: const Text(
          AppStrings.homePage,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(AppIcons.ic_Location),
          ),
        ],
      ),
      body: ListView.separated(
        itemBuilder: (context, index) {
          return PostItem(
            userName: users[index],
          );
        },
        itemCount: users.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(
            height: 24,
          );
        },
      ),
    );
  }

  mockUserFromServer() {
    for (var i = 0; i < 50; i++) {
      users.add(
        "User Number : ${i + 1}",
      );
    }
  }
}
