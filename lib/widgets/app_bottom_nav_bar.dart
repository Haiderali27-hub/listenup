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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              child: CircleAvatar(
                backgroundColor: currentRoute == 'profile'
                    ? const Color(0xFF2BA57C)
                    : const Color(0xFF0D2B55),
                radius: 20,
                child: const Icon(Icons.person, color: Colors.white),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: currentRoute == 'home'
                      ? const Color(0xFF2BA57C)
                      : const Color(0xFF0D2B55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white),
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
                Icons.settings,
                color: currentRoute == 'settings'
                    ? const Color(0xFF2BA57C)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
