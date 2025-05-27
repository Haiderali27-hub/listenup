import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sound_app/core/constants/images.dart';

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
    _testFirebase();
  }

  Future<void> _testFirebase() async {
    try {
      // Test Firebase connection
      final app = Firebase.app();
      debugPrint('Firebase Connection Success! Default app name: ${app.name}');

      // Wait for 3 seconds then navigate
      await Future.delayed(const Duration(seconds: 3));
      Get.offAll(() => const OnboardingScreen());
    } catch (e) {
      debugPrint('Firebase Connection Error: $e');
      // Still navigate after delay even if Firebase fails
      await Future.delayed(const Duration(seconds: 3));
      Get.offAll(() => const OnboardingScreen());
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
          ],
        ),
      ),
    );
  }
}
