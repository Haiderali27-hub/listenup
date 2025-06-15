import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';
import 'package:get/get.dart';
import 'package:sound_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMTokenScreen extends StatefulWidget {
  final bool fromBottomNav;

  const FCMTokenScreen({
    super.key,
    this.fromBottomNav = false,
  });

  @override
  State<FCMTokenScreen> createState() => _FCMTokenScreenState();
}

class _FCMTokenScreenState extends State<FCMTokenScreen> {
  String? _fcmToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    // try {
    //   final token = await FirebaseMessaging.instance.getToken();
    //   setState(() {
    //     _fcmToken = token;
    //     _isLoading = false;
    //   });
    // } catch (e) {
    //   setState(() {
    //     _isLoading = false;
    //   });
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text('Failed to load FCM token'),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //   }
  }

  Future<void> _copyToken() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM token copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
          'FCM Token',
          style: TextStyle(
            color: Color(0xFF0D2B55),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your FCM Token',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0D2B55),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This token is used for push notifications. You can copy it to use in your backend services.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_fcmToken == null)
              const Center(
                child: Text(
                  'Failed to load FCM token',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      _fcmToken!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2B55),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: 'settings'),
    );
  }
}

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({Key? key}) : super(key: key);

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool? notificationsEnabled;
  bool? appEnabled;
  bool? microphoneAllowed;
  bool _isLoading = false;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchUserSettings();
  }

  Future<void> _fetchUserSettings() async {
    setState(() => _isLoading = true);
    try {
      print('Fetching user settings...');
      print('Using access token: \\${AuthService.accessToken}');
      final response = await AuthService.authenticatedRequest((token) => http.get(
        Uri.parse('http://13.61.5.249:8000/auth/user/settings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      print('User settings response status: \\${response.statusCode}');
      print('User settings response body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notificationsEnabled = data['notifications_enabled'];
          appEnabled = data['app_enabled'];
          microphoneAllowed = data['microphone_allowed'];
        });
      } else {
        Get.snackbar('Error', 'Failed to fetch user settings', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('User settings fetch exception: \\${e.toString()}');
      Get.snackbar('Error', 'An error occurred. Please try again.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() => _isChangingPassword = true);
    try {
      final response = await AuthService.authenticatedRequest((token) => http.post(
        Uri.parse('http://13.61.5.249:8000/auth/user/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmPasswordController.text,
        }),
      ));
      print('Change password response status: \\${response.statusCode}');
      print('Change password response body: \\${response.body}');
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Password changed successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Failed to change password', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('Change password exception: \\${e.toString()}');
      Get.snackbar('Error', 'An error occurred. Please try again.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Change Password',
                    style: TextStyle(
                      color: Color(0xFF0D2B55),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Old Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2B55),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isChangingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Change Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
} 