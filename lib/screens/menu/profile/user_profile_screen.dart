import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';
import 'package:sound_app/core/services/user_profile_service.dart';
import 'package:sound_app/routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sound_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _nameController = TextEditingController();
  int? _currentAvatarNumber;
  String? _userEmail;
  String? _profileImageUrl;

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
      print('Fetching user info...');
      print('Using access token: \\${AuthService.accessToken}');
      final response = await AuthService.authenticatedRequest((token) => http.get(
        Uri.parse('http://13.61.5.249:8000/auth/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
      print('User info response status: \\${response.statusCode}');
      print('User info response body: \\${response.body}');
      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body);
        _nameController.text = profile['fullname'] ?? '';
        _userEmail = profile['email'] ?? '';
        _profileImageUrl = profile['profile_image'];
      }
    } catch (e) {
      print('Error fetching user info: \\${e.toString()}');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      AuthService.accessToken = null;
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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _isLoading = true);
    try {
      print('Uploading profile image...');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://13.61.5.249:8000/auth/user/profile-picture/'),
      );
      request.headers['Authorization'] = 'Bearer \\${AuthService.accessToken}';
      request.files.add(await http.MultipartFile.fromPath('profile_image', pickedFile.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Profile image upload status: \\${response.statusCode}');
      print('Profile image upload body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _profileImageUrl = data['profile_image'];
        Get.snackbar('Success', 'Profile image updated!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Failed to upload image', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('Profile image upload exception: \\${e.toString()}');
      Get.snackbar('Error', 'An error occurred. Please try again.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
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
                      onTap: _pickAndUploadImage,
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
                              child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? Image.network(_profileImageUrl!, fit: BoxFit.cover)
                                  : Image.asset(
                                      _userProfileService.getAvatarImagePath(_currentAvatarNumber ?? 1),
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
                      value: _userEmail ?? '',
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
