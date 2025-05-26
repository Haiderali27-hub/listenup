import 'package:flutter/material.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  final bool fromBottomNav;

  const SettingsScreen({
    super.key,
    this.fromBottomNav = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool isEnabled = true;
  bool microphoneAllowed = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (widget.fromBottomNav) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0D2B55),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Notifications toggle
            SettingsToggleItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
              },
            ),
            const Divider(height: 1),

            // Enable/Disable toggle
            SettingsToggleItem(
              icon: Icons.person_outline,
              title: 'Enable / Disable',
              value: isEnabled,
              onChanged: (value) {
                setState(() => isEnabled = value);
              },
            ),
            const Divider(height: 1),

            // Microphone permission toggle
            SettingsToggleItem(
              icon: Icons.mic_outlined,
              title: 'Allow your microphone',
              value: microphoneAllowed,
              onChanged: (value) {
                setState(() => microphoneAllowed = value);
              },
            ),
            const Divider(height: 1),

            // Change Password option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.lock_outline,
                color: Color(0xFF0D2B55),
                size: 24,
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to change password screen
              },
            ),
            const Divider(height: 1),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: 'settings'),
    );
  }
}

class SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: const Color(0xFF0D2B55),
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0D2B55),
      ),
    );
  }
}
