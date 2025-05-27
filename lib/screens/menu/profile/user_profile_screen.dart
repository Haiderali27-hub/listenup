import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';
import 'package:sound_app/core/services/firebase_service.dart';
import 'package:sound_app/routes/app_routes.dart';

class UserProfileScreen extends StatefulWidget {
  final bool fromBottomNav;

  const UserProfileScreen({
    super.key,
    this.fromBottomNav = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = FirebaseService();
      await firebaseService.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleLogout,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D2B55)),
                    ),
                  )
                : const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFF0D2B55),
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Image
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D2B55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Full Name field
              ProfileTextField(
                label: 'Full Name',
                value: 'Chris Pal',
                onEdit: () {
                  // TODO: Handle name edit
                },
              ),
              const SizedBox(height: 24),

              // Email field
              ProfileTextField(
                label: 'Email',
                value: 'chris214@gmail.com',
                onEdit: () {
                  // TODO: Handle email edit
                },
              ),
              const SizedBox(height: 24),

              // Password field
              ProfileTextField(
                label: 'Password',
                value: '••••••••••••••••',
                onEdit: () {
                  // TODO: Handle password edit
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: 'profile'),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFF0D2B55),
                size: 20,
              ),
              onPressed: onEdit,
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
