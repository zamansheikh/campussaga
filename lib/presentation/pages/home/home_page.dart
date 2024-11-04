import 'package:campus_saga/core/constants/update_constants.dart';
import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/services/update_checker.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
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
  String _currentVersion = CURRENT_VERSION;
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
    Future.delayed(
        Duration(
          seconds: 5,
        ), () async {
      _currentVersion = await checkUpdateFromGithub(context);
      setState(() {
        _currentVersion = _currentVersion;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.school,
                          size: 40, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Campus Saga',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Items
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Promotion'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Post'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Ranking'),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),

            const Spacer(),
            const Divider(),

            // Bottom Actions
            ListTile(
              leading: const Icon(Icons.system_update),
              title: Text(
                  '${CURRENT_VERSION == _currentVersion ? 'Up to date' : 'Update Available v$_currentVersion'}'),
              onTap: () {
                checkUpdateFromGithub(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                sl<AuthBloc>().add(SignOutEvent());
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
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
