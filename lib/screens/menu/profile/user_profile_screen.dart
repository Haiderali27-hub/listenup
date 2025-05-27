import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';
import 'package:sound_app/core/services/firebase_service.dart';
import 'package:sound_app/core/services/user_profile_service.dart';
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
  final _userProfileService = UserProfileService();
  final _firebaseService = FirebaseService();
  final _nameController = TextEditingController();
  int? _currentAvatarNumber;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userProfileService.getUserProfile();
      if (profile != null) {
        _nameController.text = profile['name'] ?? '';
        _currentAvatarNumber = profile['avatarNumber'];
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _userProfileService.updateUserProfile(
        name: _nameController.text,
        avatarNumber: _currentAvatarNumber,
      );
      if (success) {
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAvatarSelection() async {
    final selectedAvatar = await showAvatarSelectionDialog(
      context,
      currentAvatarNumber: _currentAvatarNumber,
    );

    if (selectedAvatar != null) {
      setState(() => _currentAvatarNumber = selectedAvatar);
      await _updateProfile();
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.signOut();
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
        setState(() => _isLoading = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Avatar Section
                    GestureDetector(
                      onTap: _handleAvatarSelection,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0D2B55),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _userProfileService.getAvatarImagePath(
                                  _currentAvatarNumber ?? 1,
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to change avatar',
                            style: TextStyle(
                              color: Color(0xFF0D2B55),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Full Name field
                    ProfileTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      onEdit: _updateProfile,
                    ),
                    const SizedBox(height: 24),

                    // Email field (read-only)
                    ProfileTextField(
                      label: 'Email',
                      value: _firebaseService.getCurrentUser()?.email ?? '',
                      readOnly: true,
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
  final String? value;
  final TextEditingController? controller;
  final VoidCallback? onEdit;
  final bool readOnly;

  const ProfileTextField({
    super.key,
    required this.label,
    this.value,
    this.controller,
    this.onEdit,
    this.readOnly = false,
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
              child: controller != null
                  ? TextField(
                      controller: controller,
                      readOnly: readOnly,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Text(
                      value ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
            if (onEdit != null)
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
