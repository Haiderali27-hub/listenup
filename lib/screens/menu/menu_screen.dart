import 'package:flutter/material.dart';
import 'package:sound_app/screens/menu/profile/user_profile_screen.dart';
import 'package:sound_app/screens/menu/record/record_screen.dart';
import 'package:sound_app/screens/menu/settings/settings_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '',
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Settings option
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: Color(0xFF0D2B55),
                  size: 28,
                ),
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SettingsScreen(fromBottomNav: false),
                    ),
                  );
                },
              ),
              const Divider(),
              // User Profile option
              ListTile(
                leading: const Icon(
                  Icons.person,
                  color: Color(0xFF0D2B55),
                  size: 28,
                ),
                title: const Text(
                  'User Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const UserProfileScreen(fromBottomNav: false),
                    ),
                  );
                },
              ),
              const Divider(),
              // Track Your Record option
              ListTile(
                leading: const Icon(
                  Icons.track_changes,
                  color: Color(0xFF0D2B55),
                  size: 28,
                ),
                title: const Text(
                  'Track Your Record',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const RecordScreen(fromBottomNav: false),
                    ),
                  );
                },
              ),
              const Divider(),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
