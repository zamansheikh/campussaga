import 'package:campus_saga/components/bottom_navigation_item.dart';
import 'package:campus_saga/config/app_icons.dart';
import 'package:campus_saga/pages/home_page.dart';
import 'package:campus_saga/pages/profile_page.dart';
import 'package:campus_saga/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Menus currentIndex = Menus.problem;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[currentIndex.index],
      bottomNavigationBar: MyButtonNavigation(
          onTap: (Menus value) {
            setState(() {
              currentIndex = value;
            });
          },
          currentIndex: currentIndex),
    );
  }

  final pages = [
    HomePage(),
    Center(
      child: Text("Favorite"),
    ),
    Center(
      child: Text("add"),
    ),
    Center(
      child: Text("message"),
    ),
    ProfilePage(),
  ];
}

enum Menus {
  problem,
  favorite,
  add,
  message,
  profile,
}

class MyButtonNavigation extends StatelessWidget {
  final Menus currentIndex;
  final ValueChanged<Menus> onTap;
  const MyButtonNavigation(
      {super.key, required this.onTap, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 87,
      margin: EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 17,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: BottomNavigationItem(
                      onPressed: () {
                        onTap(Menus.problem);
                      },
                      icon: AppIcons.ic_Problem,
                      current: currentIndex,
                      name: Menus.problem,
                    ),
                  ),
                  Expanded(
                    child: BottomNavigationItem(
                      onPressed: () {
                        onTap(Menus.favorite);
                      },
                      icon: AppIcons.ic_Favorite,
                      current: currentIndex,
                      name: Menus.favorite,
                    ),
                  ),
                  Spacer(),
                  Expanded(
                    child: BottomNavigationItem(
                      onPressed: () {
                        onTap(Menus.message);
                      },
                      icon: AppIcons.ic_Message,
                      current: currentIndex,
                      name: Menus.message,
                    ),
                  ),
                  Expanded(
                    child: BottomNavigationItem(
                      onPressed: () {
                        onTap(Menus.profile);
                      },
                      icon: AppIcons.ic_Profile,
                      current: currentIndex,
                      name: Menus.profile,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onTap(Menus.add),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  AppIcons.ic_Add,
                  colorFilter: ColorFilter.mode(
                      currentIndex == Menus.add
                          ? Colors.blue
                          : Colors.black.withOpacity(1),
                      BlendMode.srcIn),
                ),
                width: 64.0,
                height: 64.0,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
