import 'dart:async';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:sound_app/core/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sound_app/core/constants/images.dart';
import 'package:sound_app/routes/app_routes.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_app/services/auth_service.dart';

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
    _navigateFromSplash();
  }

  void _navigateFromSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final token = prefs.getString('access_token');
    print('SplashScreen: onboardingComplete=$onboardingComplete, token=$token');
      await Future.delayed(const Duration(seconds: 2));
    if (!onboardingComplete) {
      print('SplashScreen: Navigating to onboarding');
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (token != null && token.isNotEmpty) {
      print('SplashScreen: Navigating to home');
      AuthService.accessToken = token;
      Get.offAllNamed(AppRoutes.home);
    } else {
      print('SplashScreen: Navigating to login');
      Get.offAllNamed(AppRoutes.login);
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
