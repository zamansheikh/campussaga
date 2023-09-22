import 'package:campus_saga/app/modules/add_post/views/add_post_view.dart';
import 'package:campus_saga/app/modules/profile/views/profile_view.dart';
import 'package:campus_saga/app/modules/promotion/views/promotion_view.dart';
import 'package:campus_saga/app/modules/ranking/views/ranking_view.dart';
import 'package:flutter/material.dart';
import 'package:campus_saga/app/modules/home/views/home_view.dart';

class BottomBarView extends StatefulWidget {
  BottomBarView({super.key});
  @override
  State<BottomBarView> createState() => _BottomBarViewState();
}

class _BottomBarViewState extends State<BottomBarView> {
  var currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeView(),
          PromotionView(),
          AddPostView(),
          RankingView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15), topRight: Radius.circular(15)),
        child: BottomNavigationBar(
          iconSize: 30,
          // backgroundColor: Colors.red.shade100,

          selectedItemColor: Color(0xFF207BFF),
          unselectedItemColor: Colors.black,
          currentIndex: currentIndex,
          items: const [
            BottomNavigationBarItem(
              // backgroundColor: Color(0xFFC7DEFF),
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: 'Promotion',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_rounded),
              label: 'Add Post',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts),
              label: 'Profile',
            ), // Add more items for your navigation options
          ],
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
