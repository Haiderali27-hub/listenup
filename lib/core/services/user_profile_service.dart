import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sound_app/core/constants/images.dart';

const List<String> avatarImages = [
  avatar1,
  avatar2,
  avatar3,
  avatar4,
  avatar5,
  avatar6,
];

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch user profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Update user profile data
  Future<bool> updateUserProfile({
    required String name,
    int? avatarNumber,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final Map<String, dynamic> updateData = {
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update avatar if provided
      if (avatarNumber != null) {
        if (avatarNumber < 1 || avatarNumber > 6) {
          Get.snackbar(
            'Error',
            'Invalid avatar number. Must be between 1 and 6',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
        updateData['avatarNumber'] = avatarNumber;
      }

      await _firestore.collection('users').doc(userId).set(
        updateData,
        SetOptions(merge: true),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update user profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Get avatar image path based on avatar number (1-based index)
  String getAvatarImagePath(int avatarNumber) {
    if (avatarNumber < 1 || avatarNumber > avatarImages.length) {
      return getDefaultAvatarPath();
    }
    return avatarImages[avatarNumber - 1];
  }

  // Get default avatar if none is selected
  String getDefaultAvatarPath() {
    return avatarImages[0];
  }
}

class AvatarSelectionDialog extends StatelessWidget {
  final int? currentAvatarNumber;
  final Function(int) onAvatarSelected;

  const AvatarSelectionDialog({
    Key? key,
    this.currentAvatarNumber,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Avatar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: avatarImages.length,
              itemBuilder: (context, index) {
                final avatarNumber = index + 1;
                final isSelected = avatarNumber == currentAvatarNumber;
                
                return GestureDetector(
                  onTap: () {
                    onAvatarSelected(avatarNumber);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        avatarImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the avatar selection dialog
Future<int?> showAvatarSelectionDialog(
  BuildContext context, {
  int? currentAvatarNumber,
}) async {
  int? selectedAvatar;
  
  await showDialog(
    context: context,
    builder: (context) => AvatarSelectionDialog(
      currentAvatarNumber: currentAvatarNumber,
      onAvatarSelected: (avatarNumber) {
        selectedAvatar = avatarNumber;
      },
    ),
  );
  
  return selectedAvatar;
} 