import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../routes/app_routes.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        // Print tokens after successful login
        print('\n=== Login Successful - Token Details ===');
        
        // Print ID Token
        final idToken = await user.getIdToken();
        print('\n--- ID Token ---');
        print('ID Token: $idToken');
        print('ID Token Length: ${idToken?.length ?? 0}');
        if (idToken != null) {
          print('ID Token First 10 chars: ${idToken.substring(0, idToken.length > 10 ? 10 : idToken.length)}...');
        } else {
          print('ID Token is null');
        }
        
        // Print Access Token
        final accessToken = await user.getIdToken(true); // Force refresh to get access token
        print('\n--- Access Token ---');
        print('Access Token: $accessToken');
        print('Access Token Length: ${accessToken?.length ?? 0}');
        if (accessToken != null) {
          print('Access Token First 10 chars: ${accessToken.substring(0, accessToken.length > 10 ? 10 : accessToken.length)}...');
        } else {
          print('Access Token is null');
        }
        
        print('=======================================\n');

        // Attempt to get and print FCM token, but don't block login if it fails
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          print('\n--- FCM Token ---');
          print('FCM Token: $fcmToken');
          print('FCM Token Length: ${fcmToken?.length ?? 0}');
          if (fcmToken != null) {
            print('FCM Token First 10 chars: ${fcmToken.substring(0, fcmToken.length > 10 ? 10 : fcmToken.length)}...');
          } else {
             print('FCM Token is null');
          }
           print('========================\n');
        } catch (e) {
          print('❌ Error getting FCM token after login: $e');
          // Log the error but continue, as core authentication succeeded
        }

        Get.offAllNamed(AppRoutes.home);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        default:
          message = 'Authentication error: ${e.message}';
      }
      Get.snackbar('Login Failed', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      
      if (user != null) {
        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        Get.offAllNamed(AppRoutes.home);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        default:
          message = 'Registration error: ${e.message}';
      }
      Get.snackbar('Registration Failed', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  User? getCurrentUser() => _auth.currentUser;

  Future<void> sendPasswordResetCode(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Success',
        'Verification code has been sent to your email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-not-found':
          message = 'No user found with this email address.';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      Get.snackbar(
        'Success',
        'Password has been reset successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'expired-action-code':
          message = 'The verification code has expired.';
          break;
        case 'invalid-action-code':
          message = 'The verification code is invalid.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
