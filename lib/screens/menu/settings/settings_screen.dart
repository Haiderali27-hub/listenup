import 'package:flutter/material.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';
import 'package:sound_app/services/background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_app/services/mic_state.dart';
import 'package:sound_app/screens/menu/record/record_screen.dart';
import 'package:sound_app/screens/menu/settings/fcm_token_screen.dart';
import 'package:get/get.dart';
import 'package:sound_app/routes/app_routes.dart';
import 'package:sound_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool notificationsEnabled = false;
  bool appEnabled = false;
  bool microphoneAllowed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserSettings();
  }

  Future<void> _fetchUserSettings() async {
    setState(() => _isLoading = true);
    try {
      print('Fetching user settings...');
      final response = await AuthService.authenticatedRequest((token) => http.get(
        Uri.parse('http://13.61.5.249:8000/auth/user/settings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      print('User settings response status: ${response.statusCode}');
      print('User settings response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notificationsEnabled = data['notifications_enabled'] ?? false;
          appEnabled = data['app_enabled'] ?? false;
          microphoneAllowed = data['microphone_allowed'] ?? false;
        });
      } else {
        Get.snackbar('Error', 'Failed to fetch user settings', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('User settings fetch exception: ${e.toString()}');
      Get.snackbar('Error', 'An error occurred. Please try again.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserSetting(String key, bool value) async {
    try {
      // Update the local state for the outgoing request
      final updatedSettings = {
        'notifications_enabled': key == 'notifications_enabled' ? value : notificationsEnabled,
        'app_enabled': key == 'app_enabled' ? value : appEnabled,
        'microphone_allowed': key == 'microphone_allowed' ? value : microphoneAllowed,
      };
      print('Sending PUT to update settings: ' + updatedSettings.toString());
      final response = await AuthService.authenticatedRequest((token) => http.put(
        Uri.parse('http://13.61.5.249:8000/auth/user/settings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedSettings),
      ));
      print('Settings update response status: ${response.statusCode}');
      print('Settings update response body: ${response.body}');
      if (response.statusCode == 200) {
        print('✅ Successfully updated settings');
        await _fetchUserSettings();
      } else {
        print('❌ Failed to update settings: ${response.statusCode}');
        print('Response body: ${response.body}');
        Get.snackbar(
          'Error',
          'Failed to update settings. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ Error updating settings: $e');
      Get.snackbar(
        'Error',
        'Failed to update settings. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      _updateUserSetting('notifications_enabled', value);
              },
            ),
            const Divider(height: 1),

            // Enable/Disable toggle
            SettingsToggleItem(
              icon: Icons.person_outline,
              title: 'Enable / Disable',
                    value: appEnabled,
              onChanged: (value) {
                      setState(() => appEnabled = value);
                      _updateUserSetting('app_enabled', value);
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
                      _updateUserSetting('microphone_allowed', value);
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
                      Get.toNamed(AppRoutes.userSettings);
              },
            ),
            const Divider(height: 1),

            // FCM Token option
            ListTile(
              leading: const Icon(Icons.token),
              title: const Text('FCM Token'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FCMTokenScreen(fromBottomNav: false),
                  ),
                );
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
