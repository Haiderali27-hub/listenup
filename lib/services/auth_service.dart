import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:sound_app/routes/app_routes.dart';
import 'package:flutter/material.dart';

class AuthService {
  static String? accessToken;
  static String? refreshToken;

  static Future<void> saveTokens(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  // Global authenticated request wrapper
  static Future<http.Response> authenticatedRequest(
    Future<http.Response> Function(String accessToken) requestFn,
  ) async {
    if (accessToken == null) {
      print('[AuthService] No access token available');
      final prefs = await SharedPreferences.getInstance();
      accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        print('[AuthService] No access token in SharedPreferences');
        Get.offAllNamed(AppRoutes.login);
        throw Exception('No access token available');
      }
    }

    print('[AuthService] Using access token: \\${accessToken!.substring(0, 10)}...');
    var response = await requestFn(accessToken!);
    
    if (response.statusCode == 401) {
      print('[AuthService] Access token expired or invalid, logging out.');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      accessToken = null;
      refreshToken = null;
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Session Expired', 
        'Please log in again.', 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: const Color(0xFFB00020), 
        colorText: const Color(0xFFFFFFFF)
      );
    }
    return response;
  }
} 