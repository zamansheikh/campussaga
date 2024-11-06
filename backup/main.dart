import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'add_post_page.dart';
import 'promotions_page.dart';
import 'rankings_page.dart';
import 'profile_page.dart';

void main() {
  runApp(const CampusSagaApp());
}

class CampusSagaApp extends StatelessWidget {
  const CampusSagaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Saga',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  MainNavigationPageState createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const PromotionsPage(),
    const AddPostPage(),
    const RankingsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Promotions'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Add Post'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rankings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}