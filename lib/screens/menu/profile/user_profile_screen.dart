import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

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
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Handle logout
            },
            child: const Text(
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF0D2B55),
                radius: 20,
                child: Icon(Icons.person, color: Colors.white),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D2B55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white),
              ),
              const Icon(Icons.menu, color: Colors.grey),
            ],
          ),
        ),
      ),
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
