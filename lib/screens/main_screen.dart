import 'package:flutter/material.dart';
import 'package:gnet_app/screens/activity_screen.dart';
import 'package:gnet_app/screens/home_screen.dart';
import 'package:gnet_app/screens/profile_screen.dart';
import 'package:gnet_app/widgets/custom_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Start with Home selected
  final PageController _pageController = PageController(initialPage: 1);

  final List<Widget> _screens = [
    const ActivityScreen(),
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}