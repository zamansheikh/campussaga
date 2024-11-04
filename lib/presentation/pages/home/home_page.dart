import 'package:campus_saga/presentation/pages/home/issue_page.dart';
import 'package:campus_saga/presentation/pages/post/create_post_page.dart';
import 'package:campus_saga/presentation/pages/profile/profile_page.dart';
import 'package:campus_saga/presentation/pages/promotion/promotion_page.dart';
import 'package:campus_saga/presentation/pages/ranking/ranking_page.dart';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<Widget> pages = [];
  @override
  void initState() {
    pages = [
      IssuePage(),
      PromotionPage(),
      CreatePostPage(
        onPostCreated: () {
          setState(() {
            _currentIndex = 0; // Navigate to IssuePage
          });
        },
      ),
      RankingPage(),
      ProfilePage(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: "Promotion",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "Create Post",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: "Ranking",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
