import 'package:flutter/material.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
          'Notifications',
          style: TextStyle(
            color: Color(0xFF0D2B55),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: 'notifications'),
    );
  }
}
