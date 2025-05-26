import 'package:flutter/material.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/screens/menu/profile/user_profile_screen.dart';
import 'package:sound_app/screens/menu/settings/settings_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const AppBottomNavBar({
    super.key,
    this.currentRoute = 'home',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                if (currentRoute != 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfileScreen(),
                    ),
                  );
                }
              },
              child: Icon(
                Icons.person_outline,
                color: currentRoute == 'profile'
                    ? const Color(0xFF0D2B55)
                    : Colors.grey,
                size: 28,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (currentRoute != 'home') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D2B55),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (currentRoute != 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }
              },
              child: Icon(
                Icons.settings_outlined,
                color: currentRoute == 'settings'
                    ? const Color(0xFF0D2B55)
                    : Colors.grey,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
