import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sound_app/core/constants/images.dart';
import 'package:sound_app/core/services/firebase_service.dart';
import 'package:sound_app/routes/app_routes.dart';
import 'package:sound_app/screens/home/home_screen.dart';

import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');

      // Check authentication state
      final firebaseService = FirebaseService();
      final user = firebaseService.getCurrentUser();
      
      // Wait for 2 seconds to show splash screen
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;

      if (user != null) {
        debugPrint('User is logged in, navigating to home screen');
        Get.offAllNamed(AppRoutes.home);
      } else {
        debugPrint('No user logged in, navigating to onboarding');
        Get.offAllNamed(AppRoutes.onboarding);
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      if (!mounted) return;
      
      // Show error and navigate to onboarding
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize app. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 11, 43, 88), // Deep blue
              Color.fromARGB(255, 37, 119, 92), // Teal green
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              logo,
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'LISTEN UP',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'IoT-Powered Smart Home\nAssistance',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
