import 'package:flutter/material.dart';
import 'package:sound_app/screens/menu/profile/user_profile_screen.dart';
import 'package:sound_app/screens/menu/settings/settings_screen.dart';

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
                      builder: (context) => const SettingsScreen(),
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
                      builder: (context) => const UserProfileScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              // Bottom navigation mockup
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Profile icon (left)
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                      ),
                    ),
                    // Center mic button
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2B55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                    // Menu icon (right)
                    const Icon(
                      Icons.menu,
                      color: Colors.grey,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
