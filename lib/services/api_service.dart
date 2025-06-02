import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ApiService {
  static const String baseUrl = 'http://16.171.115.187:8000/auth/';
  static const String voiceDetectEndpoint = 'voice-detect/';
  static const String registerDeviceTokenEndpoint = 'register-device-token/';
  static const Duration timeout = Duration(seconds: 30);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getValidToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Force refresh the token
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw Exception('Failed to get valid token');
      }
      return token;
    } catch (e) {
      print('Error getting valid token: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  Future<Map<String, dynamic>> detectSound({
    required String audioPath,
    required String fcmToken,
  }) async {
    try {
      final token = await _getValidToken();
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$voiceDetectEndpoint'),
      );

      // Add the audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
        ),
      );

      // Add other fields
      request.fields['fcm_token'] = fcmToken;

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add timeout
      final response = await request.send().timeout(timeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        print('Error response: ${response.statusCode} - $responseBody');
        throw Exception('Failed to detect sound: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Error in detectSound: $e');
      if (e is TimeoutException) {
        throw Exception('Request timed out after ${timeout.inSeconds} seconds');
      }
      throw Exception('Failed to detect sound: $e');
    }
  }

  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      final token = await _getValidToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl$registerDeviceTokenEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'fcm_token': fcmToken}),
      ).timeout(timeout);

      if (response.statusCode != 200) {
        print('Failed to register device token: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to register device token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error registering device token: $e');
      if (e is TimeoutException) {
        throw Exception('Request timed out after ${timeout.inSeconds} seconds');
      }
      throw Exception('Failed to register device token: $e');
    }
  }
} 