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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final email = prefs.getString('user_email');
      
      print('SplashScreen: token=$token');
      
      if (token != null && refreshToken != null && email != null) {
        print('SplashScreen: Navigating to home');
        await AuthService.saveTokens(token, refreshToken, email);
        Get.offAllNamed(AppRoutes.home);
      } else {
        print('SplashScreen: Navigating to login');
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      print('SplashScreen: Error during initialization: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D2B55),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sound App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
